// Board creative card: board/year label, stimulus box, four parts
// with their printed marks, and a tap target. UI-only test.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/guide_bank_model.dart';
import 'package:yes_sir_ai/features/learn/widgets/board_creative_card.dart';
import 'package:yes_sir_ai/l10n/pages/guide_bank_strings.dart';
import 'package:yes_sir_ai/theme/app_theme.dart';

const _sample =
    'নিচের ছকটি লক্ষ কর: মনেরা → ২ → ৩ → ৪ → ৫ '
    'ক. ফলিত জীববিজ্ঞান কাকে বলে? '
    'খ. পেঁয়াজ কোষকে কেন প্রকৃত কোষ বলা হয়? '
    'গ. উদ্দীপকের কোন রাজ্যে বানরের অবস্থান? ব্যাখ্যা কর। '
    'ঘ. উদ্দীপকের ৩ ও ৪ নম্বর রাজ্যের মধ্যে কোনটি অধিক উন্নত? বিশ্লেষণ কর।';

const _q = GuideBankQuestion(
  id: 'bio-board-barishal-2023-creative-05-held',
  questionText: _sample,
  questionType: 'board-creative',
  section: 'board-creative',
  marks: 10,
  marksParts: [1, 2, 3, 4],
  setId: 'bio-board-barishal-2023-set-01-creative',
);

void main() {
  testWidgets('renders stimulus, four parts and printed marks', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: BoardCreativeCard(
            question: _q,
            locked: false,
            s: guideBankStringsBn,
            boardLabel: 'বরিশাল বোর্ড ২০২৩ · সেট ১ · সৃজনশীল',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.textContaining('বরিশাল বোর্ড'), findsOneWidget);
    expect(find.text('উদ্দীপক'), findsOneWidget);
    expect(find.text('ক'), findsOneWidget);
    expect(find.text('খ'), findsOneWidget);
    expect(find.text('গ'), findsOneWidget);
    expect(find.text('ঘ'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);

    await tester.tap(find.byType(BoardCreativeCard));
    expect(tapped, isTrue);
  });

  testWidgets('falls back to the full text when no 4-part shape', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: BoardCreativeCard(
            question: const GuideBankQuestion(
              id: 'x',
              questionText: 'একটি সাধারণ প্রশ্ন?',
              questionType: 'board-creative',
              section: 'board-creative',
            ),
            locked: false,
            s: guideBankStringsBn,
            onTap: () {},
          ),
        ),
      ),
    );
    expect(find.text('একটি সাধারণ প্রশ্ন?'), findsOneWidget);
    expect(find.text('উদ্দীপক'), findsNothing);
  });
}
