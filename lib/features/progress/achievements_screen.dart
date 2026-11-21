// Route: /achievements. Every badge is earned/locked from REAL
// saved milestones; locked badges show the real requirement and the
// user's real progress toward it (e.g. 3/5 quizzes).
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yes_sir_ai/core/services/progress_service.dart';
import 'package:yes_sir_ai/features/practice/widgets/practice_widgets.dart';
import 'package:yes_sir_ai/l10n/language_provider.dart';
import 'package:yes_sir_ai/l10n/pages/achievements_strings.dart';
import 'package:yes_sir_ai/theme/animated_progress.dart';
import 'package:yes_sir_ai/theme/app_theme.dart';
import 'package:yes_sir_ai/theme/app_tokens.dart';
import 'package:yes_sir_ai/theme/themed_scaffold.dart';

import 'achievement_badges.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});
  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  String _filter = 'all';
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final s = locale.languageCode == 'bn'
            ? achievementsStringsBn
            : achievementsStringsEn;
        return ThemedScaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/progress'),
            ),
            title: Text(s['title']!),
          ),
          body: FutureBuilder<ProgressSummary>(
            future: progressService.summary(),
            builder: (context, snap) {
              final sum = snap.data ?? ProgressSummary.empty;
              final quizCount = sum.attempts
                  .where((a) => a.kind == 'quiz')
                  .length;
              final modelCount = sum.attempts
                  .where((a) => a.kind == 'model')
                  .length;
              final perfect = sum.attempts.any(
                (a) => a.total > 0 && a.correct == a.total,
              );
              final genius = sum.totalAnswered >= 5 && sum.averageScore >= 90;
              final badges = buildAchievementBadges(
                quizCount: quizCount,
                modelCount: modelCount,
                perfect: perfect,
                genius: genius,
                streakDays: sum.streakDays,
              );
              final earnedCount = badges.where((b) => b.earned).length;
              final shown = badges
                  .where(
                    (b) =>
                        _filter == 'all' ||
                        (_filter == 'earned' && b.earned) ||
                        (_filter == 'locked' && !b.earned),
                  )
                  .toList();
              return ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  16 + MediaQuery.of(context).padding.bottom,
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(Sp.xl),
                    decoration: BoxDecoration(
                      gradient: dark
                          ? AppTheme.heroGradientDark
                          : AppTheme.heroGradient,
                      borderRadius: BorderRadius.circular(Rad.xl),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${s['level']!} ${sum.level} · ${sum.xp} XP",
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: Sp.xs),
                        Text(
                          '$earnedCount/${badges.length} ${s['unlocked']!}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: Sp.md),
                        AnimatedProgress(
                          value: badges.isEmpty
                              ? 0
                              : earnedCount / badges.length,
                          color: Colors.white,
                        ),
                        const SizedBox(height: Sp.xs),
                        Text(
                          "${s['nextLevel']!} ${sum.level + 1} — ${100 - sum.xp % 100} XP",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: ['all', 'earned', 'locked']
                        .map(
                          (f) => ChoiceChip(
                            label: Text(
                              f == 'all'
                                  ? s['filterAll']!
                                  : (f == 'earned'
                                        ? s['filterEarned']!
                                        : s['filterLocked']!),
                            ),
                            selected: _filter == f,
                            onSelected: (_) => setState(() => _filter = f),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, box) {
                      final w = (box.maxWidth - 12) / 2;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final b in shown)
                            SizedBox(
                              width: w,
                              child: _BadgeTile(
                                title: s[b.titleKey]!,
                                subtitle: b.progress,
                                icon: b.icon,
                                earned: b.earned,
                                earnedLabel: b.earned
                                    ? s['earned']!
                                    : s['locked']!,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  ProgressBar(
                    value: badges.isEmpty ? 0 : earnedCount / badges.length,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.go('/quiz'),
                    // The button opens the quiz; the old label was the
                    // name of a badge, not an action.
                    child: Text(s['startQuiz'] ?? s['badgeQuiz5']!),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

/// One badge tile in the grid: round medal, name, progress line and
/// a clear earned/locked state. Locked tiles stay visible but muted.
class _BadgeTile extends StatelessWidget {
  const _BadgeTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.earned,
    required this.earnedLabel,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final bool earned;
  final String earnedLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = earned ? AppTheme.primary : scheme.outline;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Sp.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: earned ? 0.15 : 0.08),
                  ),
                  child: Icon(icon, color: accent, size: 22),
                ),
                const Spacer(),
                Icon(
                  earned ? Icons.verified : Icons.lock_outline,
                  size: 16,
                  color: accent,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              earnedLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
