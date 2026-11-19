// Class 9-10 Biology lesson map: numbered lessons stay, topic-only
// labels and test-collection headings do not.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/data/class9_10_biology_lessons.dart';
import 'package:yes_sir_ai/features/learn/search_flow_types.dart';

void main() {
  test('biology chapter 1: seven numbered lessons', () {
    final ch = lessonsForChapter('biology', 9, 1);
    expect(ch.length, 7);
    expect(ch.containsKey('1.1 জীববিজ্ঞানের ধারণা'), isTrue);
    expect(ch.containsKey('1.2.1 ভৌত জীববিজ্ঞান'), isTrue);
    expect(ch.containsKey('1.5 দ্বিপদ নামকরণ পদ্ধতি'), isTrue);
    expect(ch.containsKey('জীবজগৎ'), isFalse);
  });

  test('biology chapter 2: canonical spelling wins', () {
    final ch = lessonsForChapter('biology', 9, 2);
    expect(ch.length, 11);
    expect(ch.containsKey('2.3.2 প্রাণিটিস্যু'), isTrue);
    expect(ch.containsKey('2.3.2 প্রাণি টিস্যু'), isFalse);
    expect(ch.containsKey('2.4 অঙ্গ ও তন্ত্র'), isTrue);
  });

  test('biology chapter 3: board collection labels excluded', () {
    final ch = lessonsForChapter('biology', 9, 3);
    expect(ch.length, 4);
    expect(ch.containsKey('3.2 মাইটোসিস'), isTrue);
    expect(ch.keys.any((k) => k.contains('সকল বোর্ডের')), isFalse);
  });

  test('biology chapter 4: combined roll-ups excluded', () {
    final ch = lessonsForChapter('biology', 9, 4);
    expect(ch.length, 11);
    expect(ch.containsKey('4.2.5 জীবজগতে সালোকসংশ্লেষণের গুরুত্ব'), isTrue);
    expect(ch.keys.any((k) => k.contains(' / ')), isFalse);
  });

  test('class 10 resolves the same guide; other classes stay empty', () {
    expect(
      lessonsForChapter('biology', 10, 13),
      lessonsForChapter('biology', 9, 13),
    );
    expect(lessonsForChapter('biology', 8, 1), isEmpty);
    expect(lessonsForChapter('biology', 9, 99), isEmpty);
  });

  test('every biology key is a numbered, verbatim DB value', () {
    final code = RegExp(r'^[0-9]+(\.[0-9]+)+\s');
    for (final chapterMap in class9BiologyLessons.values) {
      for (final key in chapterMap.keys) {
        expect(code.hasMatch(key), isTrue, reason: key);
        expect(key.trim(), key);
      }
    }
  });
}
