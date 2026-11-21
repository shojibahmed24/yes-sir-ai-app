// Regressions for the 2026-11-22 audit fixes that are pure logic:
// the class picker must offer 1–10, and page bookmarks must never
// pollute saved questions (the Saved list showed dead 'book:' rows).
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yes_sir_ai/core/models/creative_marks_parts.dart';
import 'package:yes_sir_ai/features/learn/class_choices.dart';
import 'package:yes_sir_ai/features/learn/learn_store.dart';
import 'package:yes_sir_ai/features/learn/widgets/creative_part_marks.dart';

void main() {
  test('classChoices always offers classes 1–10', () {
    expect(classChoices(null), [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    expect(classChoices(9), [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    // A defensive extra class never leaves the dropdown unmatched.
    expect(classChoices(12), contains(12));
    expect(classChoices(12).first, 1);
    expect(classChoices(12).last, 12);
  });

  test('book page bookmarks stay out of saved questions', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await LearnStore.toggleBookBookmark('book:math|45'), isTrue);
    expect(await LearnStore.isBookBookmarked('book:math|45'), isTrue);
    expect(await LearnStore.isSaved('book:math|45'), isFalse);
    expect(await LearnStore.savedIds(), isEmpty);
    expect((await LearnStore.summary()).savedCount, 0);
    expect(await LearnStore.toggleBookBookmark('book:math|45'), isFalse);
    expect(await LearnStore.isBookBookmarked('book:math|45'), isFalse);
  });

  test('legacy polluted saved ids are filtered from savedIds', () async {
    SharedPreferences.setMockInitialValues({
      'area2_saved_ids': ['mq1', 'book:math|45', 'mq2'],
    });
    expect(await LearnStore.savedIds(), ['mq1', 'mq2']);
    expect((await LearnStore.summary()).savedCount, 2);
  });

  test('saved questions still toggle normally', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await LearnStore.toggleSaved('mq1'), isTrue);
    expect(await LearnStore.isSaved('mq1'), isTrue);
  });

  test('creative parts order as ক→ঘ, not alphabetically', () {
    // The reported bug: alphabetical ids put ga before ka, so the
    // 1-mark slot showed a 3-mark question.
    expect(partOrderOf('x-creative-003-ka'), 0);
    expect(partOrderOf('x-creative-003-kha'), 1);
    expect(partOrderOf('x-creative-003-ga'), 2);
    expect(partOrderOf('x-creative-003-gha'), 3);
    expect(partOrderOf('x-part-2'), 1);
    expect(partOrderOf('unknown'), 99);
  });

  test('marks_parts Map is parsed in ক→ঘ order', () {
    expect(
      normalizeMarksParts({'ক': 1, 'খ': 2, 'গ': 3, 'ঘ': 4}),
      [1, 2, 3, 4],
    );
    expect(
      normalizeMarksParts({'ka': 1, 'kha': 2, 'ga': 3, 'gha': 4}),
      [1, 2, 3, 4],
    );
    expect(normalizeMarksParts([1, 2, 3, 4]), [1, 2, 3, 4]);
    expect(normalizeMarksParts({'ক': 1, 'গ': 3}), isNull); // gap
  });
}
