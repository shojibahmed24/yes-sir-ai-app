// B11: lesson ordering — syllabus codes first, compilation headings
// last. Uses the real messy values seen on the phone (class 9 science
// chapter 11) so the order cannot drift back to DB order.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/features/learn/lesson_order.dart';

void main() {
  const messy = {
    '১১.১ চল তড়িৎ': '১১.১ চল তড়িৎ',
    '১১.১.১ তড়িৎ বর্তনীর প্রতীক': '১১.১.১ তড়িৎ বর্তনীর প্রতীক',
    '১১.১.২ ব্যাটারির কার্যক্রম': '১১.১.২ ব্যাটারির কার্যক্রম',
    '১১.১.৪ বাড়িতে তড়িৎ বর্তনীর নকশা বা হাউজ ওয়ারিং':
        '১১.১.৪ বাড়িতে তড়িৎ বর্তনীর নকশা বা হাউজ ওয়ারিং',
    '১১.১.৩ ইলেকট্রনিক সার্কিট বা তড়িৎ বর্তনী':
        '১১.১.৩ ইলেকট্রনিক সার্কিট বা তড়িৎ বর্তনী',
    'মডেল টেস্ট — যাচাই ও মূল্যায়ন (PART 04)':
        'মডেল টেস্ট — যাচাই ও মূল্যায়ন (PART 04)',
    'মাস্টার ট্রেইনার প্যানেল কৃতক প্রণীত সৃজনশীল প্রশ্ন ও উত্তর':
        'মাস্টার ট্রেইনার প্যানেল কৃতক প্রণীত সৃজনশীল প্রশ্ন ও উত্তর',
  };

  test('syllabus codes sort numerically, compilations go last', () {
    final ordered = orderLessonEntries(messy);
    expect(ordered.map((e) => e.code ?? 'set').toList(), [
      '11.1',
      '11.1.1',
      '11.1.2',
      '11.1.3',
      '11.1.4',
      'set',
      'set',
    ]);
    expect(ordered.last.compilation, isTrue);
    // Nothing is dropped.
    expect(ordered.length, messy.length);
  });

  test('Bangla digits and long headings are recognised', () {
    expect(lessonCodeOf('১১.১.৩ ইলেকট্রনিক'), '11.1.3');
    expect(lessonCodeOf('2.2 পানির মানদণ্ড'), '2.2');
    expect(
      isCompilationLesson('মডেল টেস্ট — যাচাই ও মূল্যায়ন (PART 04)'),
      isTrue,
    );
    expect(isCompilationLesson('১১.১ চল তড়িৎ'), isFalse);
  });
}
