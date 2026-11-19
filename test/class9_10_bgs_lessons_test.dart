// Class 9-10 BGS lesson map: topic lessons stay; special-model set
// titles, 'ভূমিকা', duplicate spellings and combined labels do not.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/data/class9_10_bgs_lessons.dart';
import 'package:yes_sir_ai/features/learn/search_flow_types.dart';

void main() {
  test('BGS chapter 2: eight history lessons, set title excluded', () {
    final ch = lessonsForChapter('bgs', 9, 2);
    expect(ch.length, 8);
    expect(
      ch.containsKey('মুক্তিযুদ্ধের সূচনা এবং মুজিবনগর সরকারের কার্যক্রম'),
      isTrue,
    );
    expect(ch.containsKey('বাংলাদেশের স্বাধীনতা'), isFalse);
    expect(ch.containsKey('ভূমিকা'), isFalse);
  });

  test('BGS chapter 3: duplicate spelling excluded', () {
    final ch = lessonsForChapter('bgs', 9, 3);
    expect(ch.length, 8);
    expect(ch.containsKey('সৌরজগৎ'), isTrue);
    expect(ch.containsKey('সৌরজগৎ ও ভূমণ্ডল'), isFalse);
    expect(ch.containsKey('পৃথিবীতে জীব বসবাসের কারণ'), isFalse);
  });

  test('BGS chapter 10: variant excluded', () {
    final ch = lessonsForChapter('bgs', 9, 10);
    expect(ch.length, 9);
    expect(ch.containsKey('জাতীয় সম্পদের সংরক্ষণ ও অপচয়রোধ'), isTrue);
    expect(ch.containsKey('জাতীয় সম্পদের অপচয় রোধ'), isFalse);
  });

  test('BGS chapter 11: sub-topic labels excluded', () {
    final ch = lessonsForChapter('bgs', 9, 11);
    expect(ch.length, 9);
    expect(ch.containsKey('মোট জাতীয় উৎপাদন পরিমাপ'), isTrue);
    expect(ch.containsKey('মোট দেশজ উৎপাদন'), isFalse);
    expect(ch.containsKey('উন্নত দেশ'), isFalse);
  });

  test('class 10 resolves the same guide; other classes stay empty', () {
    expect(lessonsForChapter('bgs', 10, 13), lessonsForChapter('bgs', 9, 13));
    expect(lessonsForChapter('bgs', 8, 2), isEmpty);
    expect(lessonsForChapter('bgs', 9, 99), isEmpty);
  });

  test('every BGS key is verbatim and unique per chapter', () {
    for (final chapterMap in class9BgsLessons.values) {
      expect(chapterMap.keys.toSet().length, chapterMap.length);
      for (final key in chapterMap.keys) {
        expect(key.trim(), key);
        expect(key, isNotEmpty);
      }
    }
  });
}
