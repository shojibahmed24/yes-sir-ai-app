// Small marks/status pill ("নম্বর ব্যাজ"). The caller passes the
// already-formatted [label] (Bangla or Latin digits — never guessed
// here). [important] draws a tiny star only when the guide prints
// it; a missing mark shows nothing rather than a wrong badge.
import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../app_tokens.dart';

class MarksBadge extends StatelessWidget {
  const MarksBadge({
    super.key,
    required this.label,
    this.important = false,
    this.accent,
  });

  final String label;
  final bool important;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accent ?? theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Rad.pill),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (important) ...[
            Icon(Icons.star_rounded, size: IconSize.xs, color: AppTheme.amber),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
