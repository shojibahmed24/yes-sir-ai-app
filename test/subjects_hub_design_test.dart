// Subjects hub: one shared animated card per subject, a subject
// glyph, and a gradient "overall" band that stays readable.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/features/home/widgets/subject_card.dart';
import 'package:yes_sir_ai/features/home/widgets/subjects_overall_card.dart';
import 'package:yes_sir_ai/theme/animated_card.dart';

Widget _wrap(Widget child, {bool reduce = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduce),
    child: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

void main() {
  testWidgets('subject card uses the shared AnimatedCard + subject glyph', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const SubjectCard(
          subjectId: 'science',
          name: 'বিজ্ঞান',
          chapters: 10,
          done: 4,
          locked: false,
          chaptersLabel: 'অধ্যায়',
          lockedLabel: 'লকড',
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(AnimatedCard), findsOneWidget);
    expect(find.byIcon(Icons.science_outlined), findsOneWidget);
    expect(find.text('বিজ্ঞান'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('locked card shows the locked note and no progress', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const SubjectCard(
          subjectId: 'chemistry',
          name: 'রসায়ন',
          chapters: 0,
          done: 0,
          locked: true,
          chaptersLabel: 'অধ্যায়',
          lockedLabel: 'বই এখনো দেওয়া হয়নি',
        ),
      ),
    );
    await tester.pump();
    expect(find.text('বই এখনো দেওয়া হয়নি'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.lock_outlined), findsOneWidget);
  });

  testWidgets('reduced motion still shows the subject name', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SubjectCard(
          subjectId: 'math',
          name: 'গণিত',
          chapters: 3,
          done: 1,
          locked: false,
          chaptersLabel: 'অধ্যায়',
          lockedLabel: 'লকড',
        ),
        reduce: true,
      ),
    );
    await tester.pump();
    expect(find.text('গণিত'), findsOneWidget);
  });

  testWidgets('overall band is a readable gradient hero', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SubjectsOverallCard(
          title: 'সারসংক্ষেপ',
          booksLine: '৫ বই দেওয়া হয়েছে',
          lessonsLine: '১২ লেসন খোলা হয়েছে',
        ),
      ),
    );
    final band = tester.widget<Container>(
      find.byKey(const Key('subjects-hero')),
    );
    final deco = band.decoration as BoxDecoration;
    expect(deco.gradient, isNotNull);
    expect(find.text('সারসংক্ষেপ'), findsOneWidget);
    expect(find.text('১২ লেসন খোলা হয়েছে'), findsOneWidget);
  });
}
