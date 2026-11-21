// Tappable "correct / wrong / skipped" summary cards (B1).
//
// The results screens used to show three static numbers, so a
// student could not ask "which ones were wrong?". Each card is now a
// filter entry point: tapping opens the filtered review list.
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';

enum ReviewFilter { correct, wrong, skipped }

class ReviewFilterCards extends StatelessWidget {
  const ReviewFilterCards({
    super.key,
    required this.correct,
    required this.wrong,
    required this.skipped,
    required this.labels,
    required this.onOpen,
  });

  final int correct;
  final int wrong;
  final int skipped;

  /// Localized captions: {'correct', 'wrong', 'skipped'}.
  final Map<String, String> labels;
  final void Function(ReviewFilter filter) onOpen;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Card(
            count: correct,
            label: labels['correct']!,
            accent: AppTheme.success,
            icon: Icons.check_circle_outline,
            onTap: () => onOpen(ReviewFilter.correct),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Card(
            count: wrong,
            label: labels['wrong']!,
            accent: Theme.of(context).colorScheme.error,
            icon: Icons.cancel_outlined,
            onTap: () => onOpen(ReviewFilter.wrong),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Card(
            count: skipped,
            label: labels['skipped']!,
            accent: Theme.of(context).colorScheme.onSurfaceVariant,
            icon: Icons.remove_circle_outline,
            onTap: () => onOpen(ReviewFilter.skipped),
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.count,
    required this.label,
    required this.accent,
    required this.icon,
    required this.onTap,
  });
  final int count;
  final String label;
  final Color accent;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Sp.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: accent),
                  const Spacer(),
                  const Icon(Icons.chevron_right, size: 18),
                ],
              ),
              const SizedBox(height: Sp.xs),
              Text(
                '$count',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
