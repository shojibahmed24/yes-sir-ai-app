// Class 9-10 Accounting lesson map: core printed topics stay;
// combined multi-topic labels and test collections do not.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/data/class9_10_accounting_lessons.dart';
import 'package:yes_sir_ai/features/learn/search_flow_types.dart';

void main() {
  test('accounting chapter 1: five core topics', () {
    final ch = lessonsForChapter('accounting', 9, 1);
    expect(ch.length, 5);
    expect(
      ch.containsKey('হিসাববিজ্ঞানের ধারণা, উদ্দেশ্য ও প্রয়োজনীয়তা'),
      isTrue,
    );
    expect(ch.containsKey('হিসাব তথ্যের ব্যবহারকারী'), isTrue);
  });

  test('accounting chapter 3: double-entry topics', () {
    final ch = lessonsForChapter('accounting', 9, 3);
    expect(ch.length, 6);
    expect(ch.containsKey('দুতরফা দাখিলা পদ্ধতি'), isTrue);
    expect(ch.containsKey('ডেবিট-ক্রেডিট নির্ণয়ের নিয়মাবলি'), isTrue);
  });

  test('accounting chapter 7: board collection label excluded', () {
    final ch = lessonsForChapter('accounting', 9, 7);
    expect(ch.length, 6);
    expect(ch.containsKey('খতিয়ানের ধারণা ও বৈশিষ্ট্য'), isTrue);
    expect(ch.keys.any((k) => k.contains('সকল বোর্ডের')), isFalse);
  });

  test('accounting chapter 8: cash-book topics, combined labels out', () {
    final ch = lessonsForChapter('accounting', 9, 8);
    expect(ch.length, 10);
    expect(ch.containsKey('একঘরা নগদান বই'), isTrue);
    expect(ch.containsKey('দুঘরা নগদান বই'), isTrue);
    expect(ch.containsKey('তিনঘরা নগদান বই'), isTrue);
    expect(ch.containsKey('নগদ প্রাপ্তি জাবেদা ও নগদ প্রদান জাবেদা'), isFalse);
    expect(ch.containsKey('নগদ প্রাপ্তি জাবেদা ও তিনঘরা নগদান বই'), isFalse);
  });

  test('accounting chapter 10: financial statements', () {
    final ch = lessonsForChapter('accounting', 9, 10);
    expect(ch.length, 12);
    expect(ch.containsKey('বিশদ আয় বিবরণী'), isTrue);
    expect(ch.containsKey('আর্থিক অবস্থার বিবরণী'), isTrue);
  });

  test('class 10 resolves the same guide; other classes stay empty', () {
    expect(
      lessonsForChapter('accounting', 10, 12),
      lessonsForChapter('accounting', 9, 12),
    );
    expect(lessonsForChapter('accounting', 8, 1), isEmpty);
    expect(lessonsForChapter('accounting', 9, 99), isEmpty);
  });

  test('every accounting key is verbatim and unique per chapter', () {
    for (final chapterMap in class9AccountingLessons.values) {
      expect(chapterMap.keys.toSet().length, chapterMap.length);
      for (final key in chapterMap.keys) {
        expect(key.trim(), key);
        expect(key, isNotEmpty);
      }
    }
  });
}
