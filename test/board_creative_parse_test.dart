// Board creative parser: one stored row holds stimulus + four parts.
// These tests pin the printed shape and the honest null cases.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/features/learn/board_creative_parse.dart';

const _sample =
    'নিচের ছকটি লক্ষ কর: মনেরা → ২ → ৩ → ৪ → ৫ '
    'ক. ফলিত জীববিজ্ঞান কাকে বলে? '
    'খ. পেঁয়াজ কোষকে কেন প্রকৃত কোষ বলা হয়? '
    'গ. উদ্দীপকের কোন রাজ্যে বানরের অবস্থান? ব্যাখ্যা কর। '
    'ঘ. উদ্দীপকের ৩ ও ৪ নম্বর রাজ্যের মধ্যে কোনটি অধিক উন্নত? বিশ্লেষণ কর।';

void main() {
  test('splits stimulus and four labelled parts', () {
    final p = parseBoardCreative(_sample)!;
    expect(p.stimulus, startsWith('নিচের ছকটি'));
    expect(p.parts.length, 4);
    expect(p.parts.map((e) => e.label), ['ক', 'খ', 'গ', 'ঘ']);
    expect(p.parts.first.text, 'ফলিত জীববিজ্ঞান কাকে বলে?');
    expect(p.parts.last.text, contains('বিশ্লেষণ কর'));
  });

  test('returns null without part markers', () {
    expect(parseBoardCreative('সাধারণ একটি প্রশ্ন?'), isNull);
  });

  test('returns null when a part body is empty', () {
    expect(parseBoardCreative('উদ্দীপক ক. খ. প্রশ্ন'), isNull);
  });

  test('does not split a marker inside a word', () {
    final p = parseBoardCreative('উদ্দীপক কথা ক. প্রথম খ. দ্বিতীয়');
    expect(p, isNotNull);
    expect(p!.parts.length, 2);
    expect(p.stimulus, 'উদ্দীপক কথা');
  });
}
