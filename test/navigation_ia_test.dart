// Phase 2 IA tests: the bottom nav's second tab is the Subjects
// learning hub (not a bare search page), and the hub renders the
// class selector. Navigation behaviour, not phone behaviour — these
// run on the desktop test runner.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:yes_sir_ai/features/home/subjects_screen.dart';
import 'package:yes_sir_ai/features/home/widgets/home_bottom_nav.dart';
import 'package:yes_sir_ai/l10n/pages/home_strings.dart';
import 'package:yes_sir_ai/theme/app_theme.dart';
import 'package:yes_sir_ai/theme/widgets/app_chip.dart';

void main() {
  test('bottom nav labels carry a Subjects tab in both locales', () {
    expect(homeStringsBn['subjectsTab'], 'বিষয়');
    expect(homeStringsEn['subjectsTab'], 'Subjects');
    expect(homeStringsBn.keys, homeStringsEn.keys);
  });

  testWidgets('second tab navigates to the subjects hub', (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, __) => Scaffold(
            body: const Text('home'),
            bottomNavigationBar: HomeBottomNav(
              current: 0,
              labels: ['Home', 'Subjects', 'Practice', 'Progress', 'Profile'],
            ),
          ),
        ),
        GoRoute(
          path: '/home/subjects',
          builder: (_, __) => const Text('subjects'),
        ),
        GoRoute(path: '/practice', builder: (_, __) => const Text('practice')),
        GoRoute(path: '/progress', builder: (_, __) => const Text('progress')),
        GoRoute(path: '/profile', builder: (_, __) => const Text('profile')),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(routerConfig: router, theme: AppTheme.light()),
    );
    await tester.tap(find.byIcon(Icons.menu_book_outlined));
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/home/subjects',
    );
  });

  testWidgets('subjects hub shows the class selector', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const SubjectsScreen()),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppChip), findsNWidgets(10));
    expect(find.text('১'), findsOneWidget);
    expect(find.text('১০'), findsOneWidget);
  });
}
