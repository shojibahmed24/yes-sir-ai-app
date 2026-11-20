// Level + XP hero band on the Progress screen, split out to keep
// progress_screen.dart under the 250-line cap. The goal bar shows
// only when a goal is saved; the numbers come from the caller.
import 'package:flutter/material.dart';

import '../../../theme/animated_progress.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';

class ProgressHero extends StatelessWidget {
  const ProgressHero({
    super.key,
    required this.title,
    required this.goalProgress,
    required this.showProgress,
  });
  final String title;
  final double goalProgress;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(Sp.xl),
      decoration: BoxDecoration(
        gradient: dark ? AppTheme.heroGradientDark : AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(Rad.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium, color: Colors.white),
              const SizedBox(width: Sp.sm),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          if (showProgress) ...[
            const SizedBox(height: Sp.md),
            AnimatedProgress(value: goalProgress, color: Colors.white),
          ],
        ],
      ),
    );
  }
}
