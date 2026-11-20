// The paywall's benefit card: one gold-tinted card with the four
// honest benefits, split out of premium_paywall_screen.dart to keep
// that screen under the 250-line cap. Strings come from the caller
// (page-wise l10n), nothing here is invented.
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import 'premium_feature_row.dart';

class PremiumBenefitsCard extends StatelessWidget {
  const PremiumBenefitsCard({
    super.key,
    required this.voice,
    required this.books,
    required this.tests,
    required this.practice,
  });
  final String voice;
  final String books;
  final String tests;
  final String practice;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Gold-tinted wash with a gold border; ink text on it stays far
    // above WCAG AA (same constants the paywall used before).
    return Card(
      color: dark ? const Color(0xFF3D2E12) : const Color(0xFFFFF7E6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Rad.xl),
        side: BorderSide(color: AppTheme.amber.withValues(alpha: 0.40)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Sp.xl),
        child: Column(
          children: [
            PremiumFeatureRow(
              icon: Icons.mic,
              color: AppTheme.primary,
              text: voice,
            ),
            PremiumFeatureRow(
              icon: Icons.menu_book,
              color: AppTheme.secondary,
              text: books,
            ),
            PremiumFeatureRow(
              icon: Icons.assignment,
              color: AppTheme.success,
              text: tests,
            ),
            PremiumFeatureRow(
              icon: Icons.edit_note,
              color: AppTheme.amber,
              text: practice,
            ),
          ],
        ),
      ),
    );
  }
}
