// UI polish helpers (pure): subject grouping order, the search-flow
// type/hint rules, and the chapter-total cache round-trip. These were
// inline expressions before, so a wrong branch could only be caught
// by hand on a phone.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/backend_models.dart';
import 'package:yes_sir_ai/features/home/widgets/subjects_grid.dart';
import 'package:yes_sir_ai/features/learn/search_flow_chapter_fetch.dart';
import 'package:yes_sir_ai/features/learn/search_flow_list_query.dart';
import 'package:yes_sir_ai/l10n/pages/subjects_strings.dart';

SubjectInfo _s(String id, {bool locked = false, bool guide = false}) =>
    SubjectInfo(
      id: id,
      nameBn: id,
      nameEn: id,
      locked: locked,
      chapterCount: locked ? 0 : 5,
      hasGuide: guide,
    );

void main() {
  test('groupSubjects: usable first, not-added last, empty groups dropped',
      () {
    final groups = groupSubjects([
      _s('both', guide: true),
      _s('locked', locked: true),
      _s('guideonly', locked: true, guide: true),
      _s('book'),
    ], subjectsStringsBn);
    expect(groups.map((g) => g.title), [
      subjectsStringsBn['groupBoth'],
      subjectsStringsBn['groupGuide'],
      subjectsStringsBn['groupBook'],
      subjectsStringsBn['groupLocked'],
    ]);
    expect(groups[0].subjects.single.id, 'both');
    expect(groups[1].subjects.single.id, 'guideonly');
    expect(groups[2].subjects.single.id, 'book');
    expect(groups[3].subjects.single.id, 'locked');
    // Only one kind present: one group, no empty headings.
    final only = groupSubjects([_s('book')], subjectsStringsEn);
    expect(only.length, 1);
    expect(only.single.title, subjectsStringsEn['groupBook']);
  });

  test('needsType: sets and Bangla papers never need a type', () {
    bool need({
      bool set = false,
      bool b1 = false,
      bool b2 = false,
      bool p2 = false,
      bool p2Section = false,
      bool type = false,
    }) => searchFlowNeedsType(
      setMode: set,
      banglaFirst: b1,
      banglaSecond: b2,
      paper2Mode: p2,
      paper2SectionPicked: p2Section,
      typePicked: type,
    );
    expect(need(), isTrue);
    expect(need(type: true), isFalse);
    expect(need(set: true), isFalse);
    expect(need(b1: true), isFalse);
    expect(need(b2: true), isFalse);
    expect(need(p2: true), isTrue);
    expect(need(p2: true, p2Section: true), isFalse);
  });

  test('actionHint follows the same rules', () {
    String? hint({
      bool set = false,
      bool b1 = false,
      bool b2 = false,
      bool p2 = false,
      bool p2Section = false,
      bool chapter = false,
      bool needType = true,
    }) => searchFlowActionHint(
      setMode: set,
      banglaFirst: b1,
      banglaSecond: b2,
      paper2Mode: p2,
      paper2SectionPicked: p2Section,
      chapterPicked: chapter,
      needType: needType,
      s: searchFlowStrings,
    );
    expect(hint(), searchFlowStrings['actionHintBoth']);
    expect(hint(chapter: true), searchFlowStrings['actionHintType']);
    expect(hint(needType: false), searchFlowStrings['actionHintChapter']);
    expect(hint(chapter: true, needType: false), isNull);
    expect(hint(set: true), isNull);
    expect(hint(p2: true), searchFlowStrings['actionHintSection']);
    expect(hint(p2: true, p2Section: true), isNull);
  });

  test('chapter totals round-trip through the cache map', () {
    final encoded = encodeChapterTotals({3: 823, 4: 666});
    expect(decodeChapterTotals(encoded), {3: 823, 4: 666});
    expect(decodeChapterTotals(null), isNull);
    expect(decodeChapterTotals({'totals': <String, dynamic>{}}), isNull);
    expect(decodeChapterTotals({'other': 1}), isNull);
  });
}

const searchFlowStrings = {
  'actionHintBoth': 'both',
  'actionHintChapter': 'chapter',
  'actionHintType': 'type',
  'actionHintSection': 'section',
};
