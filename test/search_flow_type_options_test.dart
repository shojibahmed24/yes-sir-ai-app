// Per-subject question types: chemistry / civics get the extra guide
// types (class 9, guide mode only); every other case keeps the five
// original options. Group names match the server's grp_* values.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/features/learn/search_flow_types.dart';
import 'package:yes_sir_ai/l10n/pages/search_flow_strings.dart';

void main() {
  List<SearchFlowType> types(
    String subject, {
    bool guide = true,
    int cls = 9,
  }) => searchFlowTypesFor(guide: guide, subject: subject, schoolClass: cls);

  test(
    'chemistry class 9 guide offers the five extras after the base five',
    () {
      final t = types('chemistry');
      expect(t.sublist(0, 5), searchFlowBaseTypes);
      expect(t.sublist(5), [
        SearchFlowType.oneWord,
        SearchFlowType.knowledge,
        SearchFlowType.comprehension,
        SearchFlowType.mathProblem,
        SearchFlowType.otherPractice,
        SearchFlowType.conceptualCreative,
      ]);
    },
  );

  test('civics gets knowledge and comprehension only', () {
    expect(types('civics').sublist(5), [
      SearchFlowType.knowledge,
      SearchFlowType.comprehension,
    ]);
  });

  test('higher math lists its own exercise, activity and exercise MCQs', () {
    expect(types('higher-math'), [
      SearchFlowType.mcq,
      SearchFlowType.short,
      SearchFlowType.creative,
      SearchFlowType.exercise,
      SearchFlowType.activity,
      SearchFlowType.exerciseMcq,
      SearchFlowType.conceptualCreative,
    ]);
    expect(types('higher-math', guide: false), searchFlowBaseTypes);
    expect(types('higher-math', cls: 10), searchFlowBaseTypes);
  });

  test('math, textbook mode and other classes keep the base five', () {
    expect(types('math'), searchFlowBaseTypes);
    expect(types('chemistry', guide: false), searchFlowBaseTypes);
    expect(types('chemistry', cls: 8), searchFlowBaseTypes);
  });

  test('server section names of the extra types', () {
    expect(
      {
        for (final t in SearchFlowType.values) t: searchFlowGuideSection(t),
      }.entries.where((e) => e.key.index >= 5).map((e) => e.value).toList(),
      [
        'grp_one_word',
        'grp_knowledge',
        'grp_comprehension',
        'grp_math_problem',
        'grp_other_practice',
        'grp_exercise',
        'grp_activity',
        'grp_exercise_mcq',
        'conceptual-creative',
      ],
    );
    expect(searchFlowGuideSection(SearchFlowType.mcq), 'mcq_bank');
  });

  test('conceptual creative is its own type, never folded into creative', () {
    expect(
      searchFlowGuideSection(SearchFlowType.conceptualCreative),
      'conceptual-creative',
    );
    expect(searchFlowGuideSection(SearchFlowType.creative), 'creative');
    expect(
      searchFlowLegacyQuestionType(SearchFlowType.conceptualCreative),
      isNull,
    );
    expect(
      searchFlowTypeLabel(
        SearchFlowType.conceptualCreative,
        searchFlowStringsBn,
      ),
      'কনসেপচুয়াল সৃজনশীল',
    );
    expect(
      searchFlowTypeLabel(
        SearchFlowType.conceptualCreative,
        searchFlowStringsEn,
      ),
      'Conceptual creative',
    );
    // Binary languages only: both maps must carry the label.
    expect(searchFlowStringsBn['typeConceptualCreative'], isNotEmpty);
    expect(searchFlowStringsEn['typeConceptualCreative'], isNotEmpty);
  });

  test('extra types have no old-server question-type filter', () {
    expect(searchFlowLegacyQuestionType(SearchFlowType.oneWord), isNull);
    expect(searchFlowLegacyQuestionType(SearchFlowType.creative), 'creative');
  });

  test('guide-only types never match a textbook row', () {
    for (final t in searchFlowTypesFor(
      guide: true,
      subject: 'chemistry',
      schoolClass: 9,
    ).sublist(5)) {
      for (final raw in ['mcq', 'short', 'creative', 'task', 'problem', null]) {
        expect(searchFlowTextbookMatches(t, raw), isFalse);
      }
    }
  });
}
