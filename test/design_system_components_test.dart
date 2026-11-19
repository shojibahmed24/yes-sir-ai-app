// Phase 1 component library tests: each reusable widget renders its
// states, fires callbacks, and the preview screen lays out without
// overflow in both themes at a larger text scale.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yes_sir_ai/l10n/language_provider.dart';
import 'package:yes_sir_ai/theme/app_theme.dart';
import 'package:yes_sir_ai/theme/widgets/app_chip.dart';
import 'package:yes_sir_ai/theme/widgets/app_state_view.dart';
import 'package:yes_sir_ai/theme/widgets/marks_badge.dart';
import 'package:yes_sir_ai/theme/widgets/mcq_option_card.dart';
import 'package:yes_sir_ai/theme/widgets/section_header.dart';
import 'package:yes_sir_ai/features/design_system/design_system_screen.dart';

Widget _wrap(Widget child, {bool dark = false}) => MaterialApp(
  theme: dark ? AppTheme.dark() : AppTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('AppStateView empty/error/loading states', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const AppStateView(
          kind: AppStateKind.empty,
          title: 'Empty',
          message: 'Nothing',
        ),
      ),
    );
    expect(find.text('Empty'), findsOneWidget);
    expect(find.text('Nothing'), findsOneWidget);
    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);

    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        AppStateView(
          kind: AppStateKind.error,
          title: 'Error',
          actionLabel: 'Retry',
          onAction: () => tapped = true,
        ),
      ),
    );
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(tapped, isTrue);

    await tester.pumpWidget(
      _wrap(const AppStateView(kind: AppStateKind.loading, title: 'Loading')),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('MarksBadge shows label and optional important star', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const MarksBadge(label: '৪')));
    expect(find.text('৪'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNothing);

    await tester.pumpWidget(
      _wrap(const MarksBadge(label: '৪', important: true)),
    );
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
  });

  testWidgets('McqOptionCard states and tap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        McqOptionCard(
          label: 'খ',
          text: 'Second option',
          state: McqOptionState.selected,
          onTap: () => tapped = true,
        ),
      ),
    );
    expect(find.text('খ'), findsOneWidget);
    expect(find.text('Second option'), findsOneWidget);
    await tester.tap(find.text('Second option'));
    expect(tapped, isTrue);

    await tester.pumpWidget(
      _wrap(
        const McqOptionCard(
          label: 'গ',
          text: 'Correct',
          state: McqOptionState.correct,
        ),
      ),
    );
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    await tester.pumpWidget(
      _wrap(
        const McqOptionCard(
          label: 'ঘ',
          text: 'Wrong',
          state: McqOptionState.wrong,
        ),
      ),
    );
    expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
  });

  testWidgets('AppChip and SectionHeader render and act', (tester) async {
    var chipTapped = false;
    var actionTapped = false;
    await tester.pumpWidget(
      _wrap(
        Column(
          children: [
            AppChip(
              label: 'MCQ',
              selected: true,
              onTap: () => chipTapped = true,
            ),
            SectionHeader(
              title: 'Subjects',
              actionLabel: 'See all',
              onAction: () => actionTapped = true,
            ),
          ],
        ),
      ),
    );
    expect(find.text('MCQ'), findsOneWidget);
    await tester.tap(find.text('MCQ'));
    expect(chipTapped, isTrue);
    await tester.tap(find.text('See all'));
    expect(actionTapped, isTrue);
  });

  testWidgets('DesignSystemScreen renders in both themes without overflow', (
    tester,
  ) async {
    languageNotifier.value = const Locale('bn');
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const DesignSystemScreen()),
    );
    expect(find.text('ডিজাইন সিস্টেম'), findsOneWidget);
    expect(tester.takeException(), isNull);

    languageNotifier.value = const Locale('en');
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark(), home: const DesignSystemScreen()),
    );
    expect(find.text('Design system'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('DesignSystemScreen lays out at 1.3x text scale', (tester) async {
    languageNotifier.value = const Locale('bn');
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const DesignSystemScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
