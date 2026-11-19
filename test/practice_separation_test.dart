// Phase 4: Practice and Model Tests are separate sections on the
// practice hub, each with its own entry. UI-only (no navigation).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:yes_sir_ai/features/practice/practice_screen.dart';
import 'package:yes_sir_ai/l10n/language_provider.dart';
import 'package:yes_sir_ai/theme/app_theme.dart';

void main() {
  testWidgets('practice hub separates MCQ practice and model tests', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    languageNotifier.value = const Locale('bn');
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const PracticeScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('অনুশীলন (MCQ)'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('মডেল টেস্ট'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('মডেল টেস্ট'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('ব্যাংক মডেল টেস্ট'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('গাইড মডেল টেস্ট'), findsOneWidget);
    expect(find.text('ব্যাংক মডেল টেস্ট'), findsOneWidget);
    // The legacy duplicate tab link is gone from this hub.
    expect(find.text('প্র্যাকটিস ট্যাব'), findsNothing);
  });
}
