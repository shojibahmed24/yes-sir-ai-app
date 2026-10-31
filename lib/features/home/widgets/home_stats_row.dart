import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_theme.dart';
import '../../learn/widgets/digits.dart';

/// Real stats only: values come from LearnStore (lessons opened,
/// chapters opened, saved questions). When nothing is saved yet
/// the values are 0 — never invented scores.
/// Every card is tappable and navigates itself (go_router), so
/// HomeScreen — at the 250-line cap — needs no change:
/// today's lessons -> /home/today-lessons, opened chapters ->
/// /home/opened-chapters, saved questions -> /saved.
class HomeStatsRow extends StatelessWidget {
  const HomeStatsRow({
    super.key,
    required this.todayLabel,
    required this.chaptersLabel,
    required this.savedLabel,
    required this.values,
    required this.bangla,
  });
  final String todayLabel;
  final String chaptersLabel;
  final String savedLabel;
  final List<int> values; // [lessons today, chapters opened, saved]
  final bool bangla;

  Widget _stat(
      BuildContext context, int value, String label, String route, int i) {
    // UI palette (গ): gradient stat cards with white text. The
    // gradient stops are deep, so white stays WCAG AA on them.
    final dark = Theme.of(context).brightness == Brightness.dark;
    final gradient = dark
        ? AppTheme.statGradientsDark[i % AppTheme.statGradientsDark.length]
        : AppTheme.statGradients[i % AppTheme.statGradients.length];
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.30 : 0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => context.go(route),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Column(
                children: [
                  Text(numStr(value, bangla),
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Phase 17 (L5): equal heights. A long Bangla label wrapping to
    // two lines used to make only its card taller. IntrinsicHeight
    // sizes the row to the tallest card and stretch forces the other
    // cards to the same height.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _stat(context, values[0], todayLabel, '/home/today-lessons', 0),
          const SizedBox(width: 12),
          _stat(context, values[1], chaptersLabel, '/home/opened-chapters', 1),
          const SizedBox(width: 12),
          _stat(context, values[2], savedLabel, '/saved', 2),
        ],
      ),
    );
  }
}
