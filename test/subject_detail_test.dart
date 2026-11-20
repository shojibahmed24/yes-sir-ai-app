// Subject detail body: real counts, subject-coloured hero, one
// honest empty state, and three navigation cards.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/features/subject_detail/subject_detail_body.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

const _info = SubjectDetailInfo(
  subjectId: 'science',
  name: 'বিজ্ঞান',
  schoolClass: 9,
  chapters: 10,
  opened: 4,
);

void main() {
  testWidgets('shows the subject, class and real counts', (tester) async {
    await tester.pumpWidget(
      _wrap(const SubjectDetailBody(info: _info, bn: true)),
    );
    await tester.pump();
    expect(find.text('বিজ্ঞান'), findsOneWidget);
    // Class 9, 10 chapters, 4 opened — Bangla digits.
    expect(find.textContaining('৯'), findsWidgets);
    expect(find.textContaining('১০'), findsWidgets);
    expect(find.textContaining('৪'), findsWidgets);
  });

  testWidgets('offers the three navigation cards', (tester) async {
    await tester.pumpWidget(
      _wrap(const SubjectDetailBody(info: _info, bn: true)),
    );
    await tester.pump();
    expect(find.text('অধ্যায় ও লেসন দেখুন'), findsOneWidget);
    expect(find.text('গাইড প্রশ্ন খুঁজুন'), findsOneWidget);
    expect(find.text('অনুশীলন শুরু করুন'), findsOneWidget);
  });

  testWidgets('zero chapters shows the honest note, not an action', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const SubjectDetailBody(
          info: SubjectDetailInfo(
            subjectId: 'chemistry',
            name: 'রসায়ন',
            schoolClass: 9,
            chapters: 0,
            opened: 0,
          ),
          bn: true,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('এই বিষয়ের কোনো অধ্যায় এখনো যোগ হয়নি'), findsOneWidget);
    expect(find.text('অধ্যায় ও লেসন দেখুন'), findsNothing);
  });

  testWidgets('English locale renders English labels', (tester) async {
    await tester.pumpWidget(
      _wrap(const SubjectDetailBody(info: _info, bn: false)),
    );
    await tester.pump();
    expect(find.text('Open chapters and lessons'), findsOneWidget);
    expect(find.text('Progress 40%'), findsOneWidget);
  });
}
