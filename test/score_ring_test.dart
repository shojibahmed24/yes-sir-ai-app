// Score ring: animated celebration for a finished quiz, with a
// score-driven colour and a Reduced Motion path that still shows
// the final ring.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/features/practice/widgets/score_ring.dart';
import 'package:yes_sir_ai/theme/animated_progress.dart';
import 'package:yes_sir_ai/theme/app_theme.dart';

Widget _wrap(Widget child, {bool reduce = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduce),
    child: Scaffold(body: child),
  ),
);

void main() {
  testWidgets('renders the shared animated ring', (tester) async {
    await tester.pumpWidget(_wrap(const ScoreRing(percent: 72)));
    expect(find.byType(AnimatedProgress), findsOneWidget);
    final ring = tester.widget<AnimatedProgress>(find.byType(AnimatedProgress));
    expect(ring.ring, isTrue);
    expect(ring.value, 0.72);
  });

  testWidgets('reduced motion still shows the ring', (tester) async {
    await tester.pumpWidget(_wrap(const ScoreRing(percent: 40), reduce: true));
    expect(find.byType(AnimatedProgress), findsOneWidget);
  });

  testWidgets('colour follows the score bands', (tester) async {
    Color colorOf(int percent) =>
        tester.widget<AnimatedProgress>(find.byType(AnimatedProgress)).color!;
    await tester.pumpWidget(_wrap(const ScoreRing(percent: 85)));
    expect(colorOf(85), AppTheme.success);
    await tester.pumpWidget(_wrap(const ScoreRing(percent: 55)));
    expect(colorOf(55), AppTheme.primary);
    await tester.pumpWidget(_wrap(const ScoreRing(percent: 20)));
    expect(colorOf(20), AppTheme.error);
  });
}
