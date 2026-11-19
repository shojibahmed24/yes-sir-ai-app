// Class 9-10 Business Entrepreneurship lesson map: printed topic
// lessons stay; combined chains and test collections do not.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/data/class9_10_business_lessons.dart';
import 'package:yes_sir_ai/features/learn/search_flow_types.dart';

void main() {
  test('business chapter 1: business idea and environment topics', () {
    final ch = lessonsForChapter('business-entrepreneurship', 9, 1);
    expect(ch.length, 9);
    expect(ch.containsKey('ব্যবসায়ের ধারণা'), isTrue);
    expect(ch.containsKey('ব্যবসায়ের পরিবেশ'), isTrue);
    expect(ch.containsKey('বাংলাদেশে ব্যবসায়িক পরিবেশ'), isTrue);
  });

  test('business chapter 2: entrepreneurship qualities and risk', () {
    final ch = lessonsForChapter('business-entrepreneurship', 9, 2);
    expect(ch.length, 9);
    expect(ch.containsKey('ব্যবসায় উদ্যোক্তার গুণাবলি'), isTrue);
    expect(ch.containsKey('ব্যবসায় উদ্যোগ ও ঝুঁকির মধ্যে সম্পর্ক'), isTrue);
  });

  test('business chapter 3: self-employment topics, combined row out', () {
    final ch = lessonsForChapter('business-entrepreneurship', 9, 3);
    expect(ch.length, 7);
    expect(ch.containsKey('আত্মকর্মসংস্থানের ধারণা'), isTrue);
    expect(
      ch.containsKey(
        'আত্মকর্মসংস্থানে উদ্বুদ্ধকরণে করণীয় ও '
        'আত্মকর্মসংস্থানে প্রশিক্ষণের প্রয়োজনীয়তা',
      ),
      isFalse,
    );
  });

  test('business chapter 4: all five ownership forms', () {
    final ch = lessonsForChapter('business-entrepreneurship', 9, 4);
    expect(ch.length, 23);
    expect(ch.containsKey('একমালিকানা ব্যবসায়ের ধারণা'), isTrue);
    expect(ch.containsKey('অংশীদারি ব্যবসায়ের নিবন্ধন'), isTrue);
    expect(ch.containsKey('যৌথমূলধনি ব্যবসায়ের ধারণা'), isTrue);
    expect(ch.containsKey('সমবায় সমিতির ধারণা'), isTrue);
    expect(ch.containsKey('বাংলাদেশের রাষ্ট্রীয় ব্যবসায়'), isTrue);
  });

  test('business chapter 5: insurance, IP and licensing', () {
    final ch = lessonsForChapter('business-entrepreneurship', 9, 5);
    expect(ch.length, 10);
    expect(ch.containsKey('বিমা'), isTrue);
    expect(ch.containsKey('কপিরাইট'), isTrue);
    expect(ch.containsKey('পেটেন্ট'), isTrue);
    expect(ch.containsKey('মেধাসম্পদ'), isTrue);
  });

  test('business chapter 6: screening and projected statements', () {
    final ch = lessonsForChapter('business-entrepreneurship', 9, 6);
    expect(ch.length, 13);
    expect(ch.containsKey('ম্যাক্রোস্ক্রিনিং'), isTrue);
    expect(ch.containsKey('মাইক্রোস্ক্রিনিং'), isTrue);
    expect(ch.containsKey('প্রাক্কলিত আর্থিক বিবরণী'), isTrue);
  });

  test('business chapter 7: industry types and their scope', () {
    final ch = lessonsForChapter('business-entrepreneurship', 9, 7);
    expect(ch.length, 11);
    expect(ch.containsKey('কুটিরশিল্প'), isTrue);
    expect(ch.containsKey('বৃহৎ শিল্প'), isTrue);
    expect(
      ch.containsKey(
        'বৃহৎ শিল্প ও বাংলাদেশের আর্থ-সামাজিক প্রেক্ষাপটে '
        'বৃহৎ শিল্পের গুরুত্ব',
      ),
      isFalse,
    );
  });

  test('business chapter 8: management functions and leadership', () {
    final ch = lessonsForChapter('business-entrepreneurship', 9, 8);
    expect(ch.length, 7);
    expect(ch.containsKey('ব্যবস্থাপনার কার্যাবলি'), isTrue);
    expect(ch.containsKey('নেতৃত্বের ধারণা ও নেতৃত্বের প্রকারভেদ'), isTrue);
  });

  test('business chapters 9-12 have no lesson values, so no step', () {
    for (final chapter in [9, 10, 11, 12]) {
      expect(
        lessonsForChapter('business-entrepreneurship', 9, chapter),
        isEmpty,
        reason: 'chapter $chapter has no live lesson values',
      );
    }
  });

  test('class 10 resolves the same guide; other classes stay empty', () {
    expect(
      lessonsForChapter('business-entrepreneurship', 10, 4),
      lessonsForChapter('business-entrepreneurship', 9, 4),
    );
    expect(lessonsForChapter('business-entrepreneurship', 8, 1), isEmpty);
    expect(lessonsForChapter('business-entrepreneurship', 9, 99), isEmpty);
  });

  test('every business key is verbatim and unique per chapter', () {
    for (final chapterMap in class9BusinessLessons.values) {
      expect(chapterMap.keys.toSet().length, chapterMap.length);
      for (final key in chapterMap.keys) {
        expect(key.trim(), key);
        expect(key, isNotEmpty);
        expect(key.contains(';'), isFalse);
      }
    }
  });
}
