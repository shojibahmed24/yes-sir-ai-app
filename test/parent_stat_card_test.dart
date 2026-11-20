// Parent stat card: read-only, accent tinted, value in the accent.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/features/parent/widgets/parent_stat_card.dart';
import 'package:yes_sir_ai/theme/app_theme.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('shows icon, label and value in the accent colour', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const ParentStatCard(
          icon: Icons.local_fire_department,
          label: 'স্ট্রিক',
          value: '৪ দিন',
          color: AppTheme.amber,
        ),
      ),
    );
    expect(find.text('স্ট্রিক'), findsOneWidget);
    expect(find.text('৪ দিন'), findsOneWidget);
    final icon = tester.widget<Icon>(find.byIcon(Icons.local_fire_department));
    expect(icon.color, AppTheme.amber);
    expect(
      tester.widget<Text>(find.text('৪ দিন')).style?.color,
      AppTheme.amber,
    );
  });

  testWidgets('no buttons: parent mode stays read-only', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const ParentStatCard(
          icon: Icons.mic,
          label: 'Voice',
          value: '5 / 30 min',
          color: AppTheme.primary,
        ),
      ),
    );
    expect(find.byType(InkWell), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.byType(TextButton), findsNothing);
  });
}
