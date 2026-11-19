// Curated Class 9-10 lesson maps for Economics and General Science.
// These tests pin the selection made from the live guide lesson
// values: real lessons stay, test-collection/compilation labels do
// not. They also pin verbatim keys (the list action uses exact
// equality, so a trimmed key would silently return zero rows).
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/data/class9_10_economics_lessons.dart';
import 'package:yes_sir_ai/core/data/class9_10_science_lessons.dart';
import 'package:yes_sir_ai/features/learn/search_flow_types.dart';

void main() {
  test('economics chapter 2-3: DB codes get DB topic titles', () {
    final ch2 = lessonsForChapter('economics', 9, 2);
    expect(ch2.length, 7);
    expect(ch2['2.1'], 'অর্থনৈতিক সম্পদ');
    expect(ch2['2.4'], 'আয়, সঞ্চয় ও বিনিয়োগ');
    expect(ch2['2.6'], 'বাংলাদেশের অর্থনৈতিক কার্যাবলি');
    expect(ch2.containsKey('বাংলাদেশের অর্থনৈতিক সম্পদ'), isTrue);
    final ch3 = lessonsForChapter('economics', 9, 3);
    expect(ch3.length, 8);
    expect(ch3['3.1'], 'উপযোগ, ভোগ ও ভোক্তা');
    expect(ch3['3.8'], 'ভারসাম্য দাম ও পরিমাণ নির্ধারণ');
  });

  test('economics chapters 4-6: keys are the live printed labels', () {
    final ch4 = lessonsForChapter('economics', 9, 4);
    expect(ch4.length, 8);
    expect(ch4.containsKey('৪.১ উৎপাদন ও উৎপাদক'), isTrue);
    expect(ch4.containsKey('৪.৮ ব্যক্তিগত ও সামাজিক ব্যয়'), isTrue);
    final ch6 = lessonsForChapter('economics', 9, 6);
    expect(ch6.length, 6);
    expect(
      ch6.containsKey('৬.২ মোট দেশজ উৎপাদন (জিডিপি) পরিমাপ পদ্ধতিসমূহ'),
      isTrue,
    );
  });

  test('economics chapters 7 and 10: topics only, compilation out', () {
    final ch7 = lessonsForChapter('economics', 9, 7);
    expect(ch7.length, 7);
    expect(ch7.containsKey('অর্থ ও অর্থের প্রকারভেদ'), isTrue);
    expect(ch7.containsKey('কেন্দ্রীয় ব্যাংক'), isTrue);
    final ch10 = lessonsForChapter('economics', 9, 10);
    expect(ch10.length, 5);
    expect(ch10.containsKey('বাজেট'), isTrue);
    expect(
      ch10.keys.any((k) => k.contains('২০২১-২২')),
      isFalse,
      reason: 'budget-edition label is a compilation name, not a lesson',
    );
  });

  test('science chapter 1-3: numbered lessons only', () {
    final ch1 = lessonsForChapter('science', 9, 1);
    expect(ch1.length, 20);
    expect(ch1.containsKey('১.১ খাদ্য ও পুষ্টি'), isTrue);
    expect(ch1.containsKey('১.১.৪ খাদ্যপ্রাণ বা ভিটামিন'), isTrue);
    expect(
      ch1.containsKey('১.৮ স্বাস্থ্যরক্ষায় শরীরচর্চা এবং বিশ্রাম'),
      isTrue,
    );
    final ch2 = lessonsForChapter('science', 9, 2);
    expect(ch2.length, 15);
    expect(ch2.containsKey('২.১.১ পানির ধর্ম'), isTrue);
    expect(ch2.containsKey('২.৬.২ বাংলাদেশে বৈশ্বিক উষ্ণতার প্রভাব'), isTrue);
    final ch3 = lessonsForChapter('science', 9, 3);
    expect(ch3.length, 17);
    expect(ch3.containsKey('৩.১ রক্ত'), isTrue);
    expect(
      ch3.containsKey('৩.৬ ডায়াবেটিস বা বহুমূত্র রোগ বা মধুমেহ রোগ'),
      isTrue,
    );
  });

  test('science chapters 7, 10, 11: roll-ups and collections out', () {
    final ch7 = lessonsForChapter('science', 9, 7);
    expect(ch7.length, 11);
    expect(ch7.containsKey('৭.১.১ শক্তিশালী ও দুর্বল এসিড'), isTrue);
    expect(
      ch7.keys.any((k) => k.startsWith('৭.১ এসিড;')),
      isFalse,
      reason: 'multi-lesson roll-up is a compilation heading',
    );
    final ch10 = lessonsForChapter('science', 9, 10);
    expect(ch10.length, 7);
    expect(
      ch10.containsKey('10.2 বলের পরিমাপ ও নিউটনের দ্বিতীয় গতিসূত্র'),
      isTrue,
    );
    final ch11 = lessonsForChapter('science', 9, 11);
    expect(ch11.length, 13);
    expect(
      ch11.containsKey('11.1.3 ইলেকট্রিক সার্কিট বা তড়িৎ বর্তনী'),
      isTrue,
    );
    expect(ch11.containsKey('11.5 উন্নয়ন কার্যক্রমে শক্তির ব্যবহার'), isTrue);
  });

  test('all curated keys are verbatim and contain no compilation names', () {
    const banned = [
      'সকল বোর্ডের',
      'শীর্ষস্থানীয় স্কুল',
      'মডেল টেস্ট',
      'অধিকতর অনুশীলন',
      'পাঠ্যবইয়ের অনুশীলনীর',
      'একাধিক অধ্যায়ের',
      'মাস্টার ট্রেইনার',
    ];
    for (final chapterMap in [
      ...class9EconomicsLessons.values,
      ...class9ScienceLessons.values,
    ]) {
      for (final key in chapterMap.keys) {
        expect(key, isNotEmpty);
        expect(key.trim(), key, reason: 'key must be the live DB value');
        expect(key, isNot('ভূমিকা'), reason: 'intro heading is not a lesson');
        for (final marker in banned) {
          expect(key.contains(marker), isFalse, reason: key);
        }
      }
    }
  });

  test('class 10 resolves the same guide; other classes stay empty', () {
    expect(
      lessonsForChapter('economics', 10, 2),
      lessonsForChapter('economics', 9, 2),
    );
    expect(
      lessonsForChapter('science', 10, 2),
      lessonsForChapter('science', 9, 2),
    );
    expect(lessonsForChapter('science', 8, 2), isEmpty);
    expect(lessonsForChapter('economics', 8, 2), isEmpty);
    expect(lessonsForChapter('science', 9, 4), isEmpty);
    expect(lessonsForChapter('economics', 9, 5), isEmpty);
  });
}
