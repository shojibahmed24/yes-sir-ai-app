// Home dashboard — final small blocks: recent questions, the next
// streak badge, an offline chip and the subject skeleton. Each hides
// itself when it has nothing honest to show.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';

/// Last opened guide questions. Entries are
/// 'subject|chapter|id|snippet'; the card shows the snippet and opens
/// that subject+chapter in the search flow.
class HomeRecentQuestions extends StatelessWidget {
  const HomeRecentQuestions({
    super.key,
    required this.title,
    required this.entries,
  });
  final String title;
  final List<String> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: Sp.sm),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < entries.length && i < 3; i++) ...[
                Builder(
                  builder: (context) {
                    final p = entries[i].split('|');
                    final route = p.length >= 2
                        ? '/search-flow?subject=${p[0]}&chapter=${p[1]}'
                        : '/search-flow';
                    final snippet = p.length > 3 ? p[3] : entries[i];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.history, size: 20),
                      title: Text(
                        snippet,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: () => context.go(route),
                    );
                  },
                ),
                if (i < entries.length - 1 && i < 2) const Divider(height: 1),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// The next streak milestone (3/7/30 days), linking to achievements.
class HomeNextMilestone extends StatelessWidget {
  const HomeNextMilestone({
    super.key,
    required this.title,
    required this.label,
    required this.actionLabel,
  });
  final String title;
  final String label;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.emoji_events, color: AppTheme.primary),
        title: Text(title, style: Theme.of(context).textTheme.titleSmall),
        subtitle: Text(label),
        trailing: Text(
          actionLabel,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        onTap: () => context.go('/achievements'),
      ),
    );
  }
}

/// A quiet chip that appears only while the phone is offline.
class HomeOfflineChip extends StatelessWidget {
  const HomeOfflineChip({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snap) {
        final rows = snap.data;
        if (rows == null) return const SizedBox.shrink();
        final offline =
            rows.isEmpty || rows.every((r) => r == ConnectivityResult.none);
        if (!offline) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: Sp.sm),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(label, style: Theme.of(context).textTheme.labelSmall),
          ),
        );
      },
    );
  }
}

/// Two rows of placeholder tiles while the subject list loads.
class SubjectGridSkeleton extends StatelessWidget {
  const SubjectGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget tile() => Expanded(
      child: Container(
        height: 78,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(Rad.lg),
        ),
      ),
    );
    return Column(
      children: [
        for (var i = 0; i < 2; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          Row(children: [tile(), const SizedBox(width: 10), tile()]),
        ],
      ],
    );
  }
}
