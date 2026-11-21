// Home dashboard blocks (D1–D3): daily goal ring, today's plan and
// quick actions. Pure widgets — the screen passes real values only;
// nothing here invents a number.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../learn/widgets/digits.dart';

/// Daily goal ring: minutes done out of the saved goal, or an honest
/// "set a goal" CTA when none is saved.
class HomeGoalCard extends StatelessWidget {
  const HomeGoalCard({
    super.key,
    required this.bn,
    required this.doneMinutes,
    required this.goalMinutes,
    required this.title,
    required this.doneLabel,
    required this.setGoalLabel,
  });
  final bool bn;
  final int doneMinutes;
  final int goalMinutes;
  final String title;
  final String doneLabel;
  final String setGoalLabel;

  @override
  Widget build(BuildContext context) {
    final hasGoal = goalMinutes > 0;
    final pct = hasGoal ? (doneMinutes / goalMinutes).clamp(0.0, 1.0) : 0.0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Sp.md),
        child: Row(
          children: [
            SizedBox(
              width: 54,
              height: 54,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: hasGoal ? pct : 0,
                    strokeWidth: 6,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                  Text(
                    hasGoal ? '${(pct * 100).round()}%' : '—',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: Sp.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    hasGoal
                        ? '${numStr(doneMinutes, bn)}/${numStr(goalMinutes, bn)} $doneLabel'
                        : setGoalLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (hasGoal) const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _PlanRow {
  const _PlanRow(this.label, this.done, this.route);
  final String label;
  final bool done;
  final String route;
}

/// Three real tasks derived from today's state; taps open the screen
/// that completes them.
class HomeTodayPlan extends StatelessWidget {
  const HomeTodayPlan({super.key, required this.title, required this.rows});
  final String title;
  final List<(String, bool, String)> rows;

  @override
  Widget build(BuildContext context) {
    final items = [for (final r in rows) _PlanRow(r.$1, r.$2, r.$3)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: Sp.sm),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                ListTile(
                  dense: true,
                  leading: Icon(
                    items[i].done
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: items[i].done ? AppTheme.success : null,
                  ),
                  title: Text(items[i].label),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () => context.go(items[i].route),
                ),
                if (i < items.length - 1) const Divider(height: 1),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Five one-tap destinations students need most.
class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({super.key, required this.labels});

  /// search, practice, model test, saved, ask ai.
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    const icons = [
      Icons.search,
      Icons.fitness_center,
      Icons.assignment_outlined,
      Icons.bookmark_border,
      Icons.chat_bubble_outline,
    ];
    const routes = [
      '/search-flow',
      '/practice',
      '/guide-model-tests',
      '/saved',
      '/search-flow?source=guide',
    ];
    return Row(
      children: [
        for (var i = 0; i < labels.length && i < icons.length; i++)
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(Rad.md),
              onTap: () => context.go(routes[i]),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Icon(icons[i], size: IconSize.md),
                    const SizedBox(height: 4),
                    Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
