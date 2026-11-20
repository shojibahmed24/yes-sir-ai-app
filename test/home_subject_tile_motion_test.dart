// Home subject tile: one shared animated card, a per-subject icon,
// and content that survives Reduced Motion (no invisible tile).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/features/home/home_design.dart';
import 'package:yes_sir_ai/features/home/widgets/home_subject_tile.dart';
import 'package:yes_sir_ai/theme/animated_card.dart';

Widget _wrap(Widget child, {bool reduce = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduce),
    child: Scaffold(body: child),
  ),
);

const _tile = HomeSubjectTile(
  name: 'গণিত',
  chaptersLabel: '১২ অধ্যায়',
  subjectId: 'math',
);

void main() {
  testWidgets('tile uses the shared AnimatedCard', (tester) async {
    await tester.pumpWidget(_wrap(_tile));
    await tester.pump();
    expect(find.byType(AnimatedCard), findsOneWidget);
    expect(find.byType(Card), findsNothing, reason: 'one card style only');
  });

  testWidgets('reduced motion still shows the name and the count', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_tile, reduce: true));
    await tester.pump();
    expect(find.text('গণিত'), findsOneWidget);
    expect(find.text('১২ অধ্যায়'), findsOneWidget);
  });

  test('each subject gets its own icon, unknown ids share the fallback', () {
    expect(subjectIconFor('math'), isNot(subjectIconFor('science')));
    expect(subjectIconFor('bangla'), isNot(subjectIconFor('english')));
    expect(subjectIconFor('not-a-subject'), subjectIconFor('also-unknown'));
  });
}
