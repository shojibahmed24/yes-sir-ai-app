// R10 (2026-11-08): the English list screen renders with
// SearchFlowType.creative, so grouping runs through
// groupQuestionRows (isCreativeFamilyType). An English set
// mixing creative-family rows (one stimulus, ক খ গ ঘ) and
// plain MCQs must group ONLY the creative rows — the old
// hardcoded mcq type hid every English creative group.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/guide_bank_model.dart';
import 'package:yes_sir_ai/features/learn/widgets/guide_creative_groups.dart';
import 'package:yes_sir_ai/features/learn/widgets/guide_creative_parts.dart';

GuideBankQuestion _q(String id, String type,
        {String? sid, int? marks}) =>
    GuideBankQuestion(
        id: id,
        questionText: 'Q $id',
        questionType: type,
        stimulusId: sid,
        marks: marks);

void main() {
  test('english creative rows sharing a stimulus form one group', () {
    final rows = [
      _q('e1', 'board_creative', sid: 'eng-s1', marks: 1),
      _q('e2', 'board_creative', sid: 'eng-s1', marks: 2),
      _q('e3', 'board_creative', sid: 'eng-s1', marks: 3),
      _q('e4', 'board_creative', sid: 'eng-s1', marks: 4),
      _q('m1', 'mcq'),
      _q('m2', 'mcq'),
    ];
    final groups = groupQuestionRows(
        [for (var i = 0; i < rows.length; i++) (i, rows[i])]);
    // 1 creative group of 4 + 2 MCQ singletons.
    expect(groups.length, 3);
    expect(groups[0].parts.length, 4);
    expect(groups[0].stimulusId, 'eng-s1');
    expect(isCreativePatternGroup(
        [for (final p in groups[0].parts) p.$2]), isTrue);
    expect(groups[1].parts.length, 1);
    expect(groups[2].parts.length, 1);
  });

  test('creative rows under different stimuli stay separate', () {
    final rows = [
      _q('a1', 'creative', sid: 's-a', marks: 1),
      _q('a2', 'creative', sid: 's-a', marks: 2),
      _q('b1', 'creative', sid: 's-b', marks: 1),
      _q('b2', 'creative', sid: 's-b', marks: 2),
    ];
    final groups = groupQuestionRows(
        [for (var i = 0; i < rows.length; i++) (i, rows[i])]);
    expect(groups.length, 2);
    expect(groups.map((g) => g.parts.length), [2, 2]);
  });

  test('family gate: only creative-family types group', () {
    expect(isCreativeFamilyType('creative'), isTrue);
    expect(isCreativeFamilyType('board_creative'), isTrue);
    expect(isCreativeFamilyType('chapter_model_creative'), isTrue);
    expect(isCreativeFamilyType('special_model_creative'), isTrue);
    expect(isCreativeFamilyType('mcq'), isFalse);
    expect(isCreativeFamilyType('short'), isFalse);
  });
}
