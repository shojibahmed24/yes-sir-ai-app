// Feature row: icon in a tinted chip, text beside it, caller accent.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/features/premium/widgets/premium_feature_row.dart';
import 'package:yes_sir_ai/theme/app_theme.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('shows the icon in the caller colour and the text', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const PremiumFeatureRow(
          icon: Icons.mic,
          text: 'ভয়েস টিউটর',
          color: AppTheme.primary,
        ),
      ),
    );
    expect(find.text('ভয়েস টিউটর'), findsOneWidget);
    final icon = tester.widget<Icon>(find.byIcon(Icons.mic));
    expect(icon.color, AppTheme.primary);
  });

  testWidgets('two rows can carry different accents', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const Column(
          children: [
            PremiumFeatureRow(
              icon: Icons.mic,
              text: 'A',
              color: AppTheme.primary,
            ),
            PremiumFeatureRow(
              icon: Icons.book,
              text: 'B',
              color: AppTheme.amber,
            ),
          ],
        ),
      ),
    );
    expect(tester.widget<Icon>(find.byIcon(Icons.mic)).color, AppTheme.primary);
    expect(tester.widget<Icon>(find.byIcon(Icons.book)).color, AppTheme.amber);
  });
}
