// Phase 3 lesson hub: content types are separate cards and each card
// opens the right existing flow. Navigation-only test on the desktop
// runner (not phone behaviour).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:yes_sir_ai/features/learn/lesson_hub_screen.dart';
import 'package:yes_sir_ai/theme/app_theme.dart';

GoRouter _router() => GoRouter(
  initialLocation: '/lesson-hub',
  routes: [
    GoRoute(
      path: '/lesson-hub',
      builder: (_, __) => const LessonHubScreen(
        subjectId: 'math',
        schoolClass: 9,
        chapter: 2,
        lesson: '2.1',
        lessonTitle: 'সেট',
      ),
    ),
    GoRoute(path: '/search-flow-list', builder: (_, __) => const Text('list')),
    GoRoute(
      path: '/guide-model-tests',
      builder: (_, __) => const Text('model'),
    ),
    GoRoute(
      path: '/search-flow-board',
      builder: (_, __) => const Text('board'),
    ),
  ],
);

void main() {
  testWidgets('lesson hub lists the five content types', (tester) async {
    await tester.pumpWidget(
      MaterialApp.router(routerConfig: _router(), theme: AppTheme.light()),
    );
    await tester.pumpAndSettle();

    expect(find.text('বহুনির্বাচনী (MCQ)'), findsOneWidget);
    expect(find.text('সৃজনশীল'), findsOneWidget);
    expect(find.text('সংক্ষিপ্ত উত্তর'), findsOneWidget);
    expect(find.text('মডেল টেস্ট'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('বোর্ড প্রশ্ন'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('বোর্ড প্রশ্ন'), findsOneWidget);
  });

  testWidgets('MCQ card opens the list with type and lesson', (tester) async {
    final router = _router();
    await tester.pumpWidget(
      MaterialApp.router(routerConfig: router, theme: AppTheme.light()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('বহুনির্বাচনী (MCQ)'));
    await tester.pumpAndSettle();
    final uri = router.routerDelegate.currentConfiguration.uri;
    expect(uri.path, '/search-flow-list');
    expect(uri.queryParameters['type'], 'mcq');
    expect(uri.queryParameters['lesson'], '2.1');
    expect(uri.queryParameters['returnTo'], isNotNull);
  });

  testWidgets('hub shows all lessons when no lesson is given', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const LessonHubScreen(
          subjectId: 'science',
          schoolClass: 9,
          chapter: 2,
        ),
      ),
    );
    expect(find.textContaining('সব লেসন'), findsOneWidget);
    expect(find.text('বিজ্ঞান'), findsOneWidget);
  });
}
