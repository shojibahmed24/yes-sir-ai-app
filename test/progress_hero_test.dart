// Progress hero: level + XP always visible; the goal bar only when a
// goal exists, and Reduced Motion never hides it.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/features/progress/widgets/progress_hero.dart';
import 'package:yes_sir_ai/theme/animated_progress.dart';

Widget _wrap(Widget child, {bool reduce = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduce),
    child: Scaffold(body: child),
  ),
);

void main() {
  testWidgets('shows level and the goal bar when a goal exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const ProgressHero(
          title: 'লেভেল ৩ · ২৪০ XP',
          goalProgress: 0.5,
          showProgress: true,
        ),
      ),
    );
    expect(find.text('লেভেল ৩ · ২৪০ XP'), findsOneWidget);
    expect(find.byType(AnimatedProgress), findsOneWidget);
  });

  testWidgets('no goal means no bar, not a zero bar', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const ProgressHero(
          title: 'Level 1 · 0 XP',
          goalProgress: 0,
          showProgress: false,
        ),
      ),
    );
    expect(find.byType(AnimatedProgress), findsNothing);
  });

  testWidgets('reduced motion keeps the title and the bar', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const ProgressHero(
          title: 'Level 2 · 90 XP',
          goalProgress: 1,
          showProgress: true,
        ),
        reduce: true,
      ),
    );
    expect(find.text('Level 2 · 90 XP'), findsOneWidget);
    expect(find.byType(AnimatedProgress), findsOneWidget);
  });
}
