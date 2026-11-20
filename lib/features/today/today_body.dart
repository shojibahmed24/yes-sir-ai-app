// Today body: a pure widget (no I/O). Every number comes from the
// caller (LearnStore/LocalStore); a missing goal shows the honest
// "not set" note instead of a made-up target.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/animated_card.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import '../home/home_design.dart';
import '../learn/widgets/digits.dart';
import 'today_strings.dart';

class TodayInfo {
  const TodayInfo({
    required this.todayLessons,
    required this.goalMinutes,
    required this.totalLessons,
    required this.chaptersOpened,
    required this.savedCount,
  });
  final int todayLessons;
  final int goalMinutes;
  final int totalLessons;
  final int chaptersOpened;
  final int savedCount;
}

class TodayBody extends StatelessWidget {
  const TodayBody({super.key, required this.info, required this.bn});

  final TodayInfo info;
  final bool bn;

  @override
  Widget build(BuildContext context) {
    final s = bn ? todayStringsBn : todayStringsEn;
    final dark = Theme.of(context).brightness == Brightness.dark;
    // The profile goal is in MINUTES and the app does not track study
    // minutes, so the two numbers are never divided into a fake
    // percentage: lessons today stands alone and the goal is shown
    // as the plain target it is.
    final goal = info.goalMinutes;
    return ListView(
      padding: const EdgeInsets.all(HomeDesign.screenPadding),
      children: [
        Container(
          padding: const EdgeInsets.all(Sp.xl),
          decoration: BoxDecoration(
            gradient: dark ? AppTheme.heroGradientDark : AppTheme.heroGradient,
            borderRadius: BorderRadius.circular(Rad.xl),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Sp.md),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.today_outlined, color: Colors.white),
              ),
              const SizedBox(width: Sp.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s['todayLessons']!,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.white70),
                    ),
                    Text(
                      _n(info.todayLessons),
                      style: Theme.of(
                        context,
                      ).textTheme.headlineLarge?.copyWith(color: Colors.white),
                    ),
                    Text(
                      goal > 0
                          ? '${s['goalLabel']!}: ${_n(goal)}'
                          : s['goalNone']!,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Sp.xl),
        Row(
          children: [
            Expanded(
              child: _Stat(
                value: info.totalLessons,
                label: s['totalLessons']!,
                color: AppTheme.primary,
                bn: bn,
              ),
            ),
            const SizedBox(width: Sp.md),
            Expanded(
              child: _Stat(
                value: info.chaptersOpened,
                label: s['chaptersOpened']!,
                color: AppTheme.success,
                bn: bn,
              ),
            ),
            const SizedBox(width: Sp.md),
            Expanded(
              child: _Stat(
                value: info.savedCount,
                label: s['savedCount']!,
                color: AppTheme.amber,
                bn: bn,
              ),
            ),
          ],
        ),
        const SizedBox(height: Sp.xl),
        if (info.todayLessons == 0) ...[
          Text(s['empty']!, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: Sp.xs),
          Text(s['emptySub']!),
          const SizedBox(height: Sp.lg),
        ],
        _Action(
          icon: Icons.play_arrow_rounded,
          title: s['startLearning']!,
          color: AppTheme.primary,
          onTap: () => context.go('/home/subjects'),
        ),
        const SizedBox(height: Sp.md),
        _Action(
          icon: Icons.fitness_center,
          title: s['practice']!,
          color: AppTheme.success,
          onTap: () => context.go('/practice'),
        ),
        const SizedBox(height: Sp.md),
        _Action(
          icon: Icons.search,
          title: s['findQuestion']!,
          color: AppTheme.secondary,
          onTap: () => context.go('/search-flow'),
        ),
      ],
    );
  }

  String _n(int v) => numStr(v, bn);
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    required this.color,
    required this.bn,
  });
  final int value;
  final String label;
  final Color color;
  final bool bn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Sp.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Rad.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            numStr(value, bn),
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: color),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      accent: color,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(Sp.lg),
        child: Row(
          children: [
            Icon(icon, color: color, size: IconSize.md),
            const SizedBox(width: Sp.md),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
