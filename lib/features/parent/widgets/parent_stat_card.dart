// Read-only stat card for the parent dashboard. No buttons that
// change anything — parent mode is view-only by design. The accent
// tints the card and the icon so five stats read apart at a glance.
import 'package:flutter/material.dart';

import '../../../theme/app_tokens.dart';

class ParentStatCard extends StatelessWidget {
  const ParentStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Sp.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Rad.md),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: Sp.sm),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
