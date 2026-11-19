// Phase-5: the multi-key hint on the shared question card —
// shown only when the item accepts more than one answer.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/backend_models.dart';
import 'package:yes_sir_ai/features/practice/widgets/practice_widgets.dart';

QuizItem _item({List<int> accepted = const []}) => QuizItem(
      id: 'q1',
      questionBn: 'প্রশ্ন?',
      questionEn: 'Question?',
      options: const ['A', 'B', 'C', 'D'],
      correctIndex: 1,
      correctIndices: accepted,
    );

void main() {
  testWidgets('multi-key item shows the hint; single-key does not',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: QuizQuestionCard(
                item: _item(accepted: [1, 3]),
                bangla: true,
                hint: 'HINT'))));
    expect(find.text('HINT'), findsOneWidget);
    expect(find.text('প্রশ্ন?'), findsOneWidget);

    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: QuizQuestionCard(
                item: _item(), bangla: true, hint: 'HINT'))));
    expect(find.text('HINT'), findsNothing);
    expect(find.text('প্রশ্ন?'), findsOneWidget);
  });
}
