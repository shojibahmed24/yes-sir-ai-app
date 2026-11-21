// Home dashboard — D4 blocks: this week's activity, the REAL weak
// chapters and the next weekly model test. Each card is hidden when
// it has no honest data (no invented rows).
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';

/// Seven bars, oldest → today. [activeDays] is how many of the last
/// seven dates appear in the stored activity list; each bar is filled
/// when that day was active.
class HomeWeekActivity extends StatelessWidget {
  const HomeWeekActivity({
    super.key,
    required this.title,
    required this.days,
    required this.active,
    required this.countLabel,
  });
  final String title;
  final List<String> days; // ['শনি', ... 'শুক্র']
  final List<bool> active;
  final String countLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            Text(countLabel, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: Sp.sm),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(Sp.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < active.length; i++)
                  Expanded(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 32,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: 14,
                              height: active[i] ? 28 : 8,
                              decoration: BoxDecoration(
                                color: active[i]
                                    ? AppTheme.primary
                                    : colors.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          i < days.length ? days[i] : '',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Up to two real weak chapters; tapping starts revision practice.
class HomeWeakTopics extends StatelessWidget {
  const HomeWeakTopics({
    super.key,
    required this.title,
    required this.labels,
    required this.emptyLabel,
    required this.actionLabel,
  });
  final String title;
  final List<String> labels;
  final String emptyLabel;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: Sp.sm),
        Card(
          child: Column(
            children: [
              if (labels.isEmpty)
                ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: Text(emptyLabel),
                )
              else
                for (final l in labels)
                  ListTile(
                    leading: const Icon(
                      Icons.psychology,
                      color: AppTheme.error,
                    ),
                    title: Text(l),
                    trailing: Text(actionLabel),
                    onTap: () => context.go('/practice'),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Next Saturday's model test: computed on the phone, no server call.
class HomeUpcomingTest extends StatelessWidget {
  const HomeUpcomingTest({
    super.key,
    required this.title,
    required this.daysLeftLabel,
    required this.actionLabel,
  });
  final String title;
  final String daysLeftLabel;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.event_available, color: AppTheme.primary),
        title: Text(title),
        subtitle: Text(daysLeftLabel),
        trailing: Text(
          actionLabel,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        onTap: () => context.go('/guide-model-tests'),
      ),
    );
  }
}
