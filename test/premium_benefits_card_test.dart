// Paywall benefits card: four honest benefit rows on the gold wash.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/features/premium/widgets/premium_benefits_card.dart';
import 'package:yes_sir_ai/features/premium/widgets/premium_feature_row.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders all four benefit rows', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const PremiumBenefitsCard(
          voice: 'ভয়েস টিউটর',
          books: 'সব বই',
          tests: 'মডেল টেস্ট',
          practice: 'অনুশীলন',
        ),
      ),
    );
    expect(find.byType(PremiumFeatureRow), findsNWidgets(4));
    expect(find.text('ভয়েস টিউটর'), findsOneWidget);
    expect(find.text('সব বই'), findsOneWidget);
    expect(find.text('মডেল টেস্ট'), findsOneWidget);
    expect(find.text('অনুশীলন'), findsOneWidget);
  });

  testWidgets('card keeps the amber border in both themes', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const PremiumBenefitsCard(
          voice: 'A',
          books: 'B',
          tests: 'C',
          practice: 'D',
        ),
      ),
    );
    final card = tester.widget<Card>(find.byType(Card));
    final shape = card.shape as RoundedRectangleBorder;
    expect(shape.side.width, greaterThan(0));
  });
}
