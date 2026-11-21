// S5 progress: chapter keys are class-stamped, so class 6 progress
// never shows up in class 9. Legacy keys (no class) keep counting, so
// an existing install never loses its opened chapters.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/features/home/opened_chapters_screen.dart';
import 'package:yes_sir_ai/features/learn/learn_store.dart';
import 'package:yes_sir_ai/features/learn/lesson_selection.dart';

void main() {
  test('parseChapterKey: legacy, class-stamped and malformed', () {
    final legacy = LearnStore.parseChapterKey('math|3');
    expect(legacy?.$1, isNull);
    expect(legacy?.$2, 'math');
    expect(legacy?.$3, 3);

    final stamped = LearnStore.parseChapterKey('9|math|3');
    expect(stamped?.$1, 9);
    expect(stamped?.$2, 'math');
    expect(stamped?.$3, 3);

    expect(LearnStore.parseChapterKey('math'), isNull);
    expect(LearnStore.parseChapterKey('math|x'), isNull);
    expect(LearnStore.parseChapterKey('math|0'), isNull);
    expect(LearnStore.parseChapterKey('|2'), isNull);
    expect(LearnStore.parseChapterKey('x|math|3'), isNull);
    expect(LearnStore.parseChapterKey('9||3'), isNull);
  });

  test('openedChapterCount is per class, legacy keys still count', () {
    const keys = ['6|math|2', '9|math|3', '9|science|1', 'math|4'];
    expect(LearnStore.openedChapterCount(keys, 9, 'math'), 2); // 3 + legacy 4
    expect(LearnStore.openedChapterCount(keys, 6, 'math'), 2); // 2 + legacy 4
    expect(LearnStore.openedChapterCount(keys, 9, 'science'), 1);
    expect(LearnStore.openedChapterCount(keys, 8, 'science'), 0);
  });

  test('lesson chapterKey carries the class when known', () {
    final withClass = LessonSelection(
      subject: 'math',
      chapter: 3,
      page: 45,
      problem: 5,
      schoolClass: 9,
    );
    expect(withClass.chapterKey, '9|math|3');
    final noClass = LessonSelection(
      subject: 'math',
      chapter: 3,
      page: 45,
      problem: 5,
    );
    expect(noClass.chapterKey, 'math|3');
  });

  test('chapterOpened is per class and per chapter', () {
    const keys = ['6|math|2', '9|math|3', 'math|4'];
    expect(LearnStore.chapterOpened(keys, 9, 'math', 3), isTrue);
    expect(LearnStore.chapterOpened(keys, 9, 'math', 2), isFalse);
    expect(LearnStore.chapterOpened(keys, 6, 'math', 2), isTrue);
    expect(LearnStore.chapterOpened(keys, 9, 'math', 4), isTrue); // legacy
    expect(LearnStore.chapterOpened(keys, 9, 'science', 3), isFalse);
  });

  test('groupOpenedChapters accepts class-stamped keys', () {
    final groups = groupOpenedChapters([
      '9|math|3',
      '6|math|2',
      'math|4',
      '9|science|1',
    ]);
    expect(groups.map((g) => g.subject), ['math', 'science']);
    expect(groups[0].chapters, [2, 3, 4]);
    expect(groups[1].chapters, [1]);
  });
}
