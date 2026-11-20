// One benefit row on the paywall. Pure display, no navigation. The
// caller picks the accent so each benefit reads apart and no icon
// hardcodes a colour outside the palette.
import 'package:flutter/material.dart';

import '../../../theme/app_tokens.dart';

class PremiumFeatureRow extends StatelessWidget {
  const PremiumFeatureRow({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
  });
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Sp.xs),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(Sp.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(Rad.sm),
            ),
            child: Icon(icon, color: color, size: IconSize.sm),
          ),
          const SizedBox(width: Sp.md),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
