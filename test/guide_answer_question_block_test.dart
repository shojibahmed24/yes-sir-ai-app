// Guide answer question block: question card + MCQ options (or the
// honest option-less notice). Rendering only — the try-first state
// belongs to the body that passes the resolved index.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/guide_bank_model.dart';
import 'package:yes_sir_ai/features/learn/widgets/guide_answer_question_block.dart';
import 'package:yes_sir_ai/features/learn/widgets/guide_mcq_options_card.dart';
import 'package:yes_sir_ai/l10n/pages/guide_bank_strings.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

const _mcq = GuideBankQuestion(
  id: 'q1',
  questionText: '২ + ২ কত?',
  questionType: 'mcq',
  options: ['২', '৪', '৬', '৮'],
);

Widget _block(GuideBankQuestion q, {int? key, VoidCallback? onAttempted}) =>
    _wrap(
      GuideAnswerQuestionBlock(
        q: q,
        fontSize: 16,
        s: guideBankStringsBn,
        correctOptionIndex: key,
        acceptedIndices: null,
        onAttempted: onAttempted ?? () {},
        translate: false,
      ),
    );

void main() {
  testWidgets('renders the question text', (tester) async {
    await tester.pumpWidget(_block(_mcq));
    expect(find.text('২ + ২ কত?', findRichText: true), findsOneWidget);
  });

  testWidgets('keyed MCQ shows options and reports the first pick', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      _block(_mcq, key: 1, onAttempted: () => attempts++),
    );
    expect(find.byType(GuideMcqOptionsCard), findsOneWidget);
    await tester.tap(find.text('২', findRichText: true));
    await tester.pump();
    expect(attempts, 1);
  });

  testWidgets('display-only MCQ offers options but no feedback', (
    tester,
  ) async {
    await tester.pumpWidget(_block(_mcq));
    expect(find.byType(GuideMcqOptionsCard), findsOneWidget);
    expect(find.text('২', findRichText: true), findsOneWidget);
  });

  testWidgets('option-less MCQ shows the honest notice, not options', (
    tester,
  ) async {
    const q = GuideBankQuestion(
      id: 'q2',
      questionText: 'কোনটি সঠিক?',
      questionType: 'mcq',
    );
    await tester.pumpWidget(_block(q));
    expect(find.byType(GuideMcqOptionsCard), findsNothing);
    expect(
      find.text(guideBankStringsBn['optionsMissing']!, findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('non-MCQ rows render the question only', (tester) async {
    const q = GuideBankQuestion(
      id: 'q3',
      questionText: 'সংক্ষেপে লেখো।',
      questionType: 'short',
    );
    await tester.pumpWidget(_block(q));
    expect(find.byType(GuideMcqOptionsCard), findsNothing);
    expect(find.text('সংক্ষেপে লেখো।', findRichText: true), findsOneWidget);
  });
}
