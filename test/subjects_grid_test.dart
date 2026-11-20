// Subject hub (S2/S3): the card badge must state what a subject
// really has (book / guide / both) from server flags, and the
// subject search must match Bangla name, English name and id.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/backend_models.dart';
import 'package:yes_sir_ai/features/home/widgets/subject_card.dart';
import 'package:yes_sir_ai/features/home/widgets/subjects_grid.dart';

const _math = SubjectInfo(
  id: 'math',
  nameBn: 'গণিত',
  nameEn: 'Mathematics',
  locked: false,
  chapterCount: 8,
);

Widget _card({
  required bool locked,
  required bool hasGuide,
  int chapters = 0,
}) =>
    MaterialApp(
      home: Scaffold(
        body: SubjectCard(
          name: 'গণিত',
          chapters: chapters,
          done: 0,
          locked: locked,
          guideOnly: locked && hasGuide,
          guideLabel: 'গাইড আছে',
          hasGuide: hasGuide,
          badgeBook: 'বই',
          badgeGuide: 'গাইড',
          badgeBoth: 'বই + গাইড',
          subjectId: 'math',
          chaptersLabel: 'টি অধ্যায়',
          lockedLabel: 'লক',
        ),
      ),
    );

void main() {
  test('subject search matches Bangla name, English name and id', () {
    expect(subjectMatches(_math, ''), isTrue);
    expect(subjectMatches(_math, 'গণি'), isTrue);
    expect(subjectMatches(_math, 'math'), isTrue);
    expect(subjectMatches(_math, 'MATH'), isTrue);
    expect(subjectMatches(_math, '  mathematics '), isTrue);
    expect(subjectMatches(_math, 'physics'), isFalse);
  });

  testWidgets('badge: book only', (tester) async {
    await tester.pumpWidget(
      _card(locked: false, hasGuide: false, chapters: 8),
    );
    expect(find.text('বই'), findsOneWidget);
    expect(find.text('গাইড'), findsNothing);
  });

  testWidgets('badge: guide only (locked, no textbook)', (tester) async {
    await tester.pumpWidget(_card(locked: true, hasGuide: true));
    expect(find.text('গাইড'), findsOneWidget);
    expect(find.text('গাইড আছে'), findsOneWidget);
  });

  testWidgets('badge: book and guide', (tester) async {
    await tester.pumpWidget(
      _card(locked: false, hasGuide: true, chapters: 8),
    );
    expect(find.text('বই + গাইড'), findsOneWidget);
  });

  testWidgets('badge: no book and no guide stays locked', (tester) async {
    await tester.pumpWidget(_card(locked: true, hasGuide: false));
    expect(find.text('বই'), findsNothing);
    expect(find.text('গাইড'), findsNothing);
    expect(find.text('লক'), findsOneWidget);
  });
}
