// Subject detail body: a pure widget (no I/O) so it is testable.
// Counts are REAL: chapters from the subject list, opened chapters
// from LearnStore. Nothing here invents a percentage.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/animated_card.dart';
import '../../theme/animated_progress.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import '../home/home_design.dart';
import '../learn/widgets/digits.dart';
import 'subject_detail_strings.dart';

/// Verified snapshot the detail screen renders: subject id, display
/// name, class, total chapters and how many the student has opened.
class SubjectDetailInfo {
  const SubjectDetailInfo({
    required this.subjectId,
    required this.name,
    required this.schoolClass,
    required this.chapters,
    required this.opened,
  });
  final String subjectId;
  final String name;
  final int schoolClass;
  final int chapters;
  final int opened;
}

class SubjectDetailBody extends StatelessWidget {
  const SubjectDetailBody({
    super.key,
    required this.info,
    required this.bn,
    this.onOpenChapters,
    this.onOpenGuide,
    this.onOpenPractice,
  });

  final SubjectDetailInfo info;
  final bool bn;
  final VoidCallback? onOpenChapters;
  final VoidCallback? onOpenGuide;
  final VoidCallback? onOpenPractice;

  @override
  Widget build(BuildContext context) {
    final s = bn ? subjectDetailStringsBn : subjectDetailStringsEn;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppTheme.subjectColorFor(info.subjectId, dark: dark);
    final progress = info.chapters == 0
        ? 0.0
        : (info.opened / info.chapters).clamp(0.0, 1.0);
    return ListView(
      padding: const EdgeInsets.all(HomeDesign.screenPadding),
      children: [
        Container(
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
                  Container(
                    padding: const EdgeInsets.all(Sp.sm),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(Rad.sm),
                    ),
                    child: Icon(
                      subjectIconFor(info.subjectId),
                      size: IconSize.md,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: Sp.md),
                  Expanded(
                    child: Text(
                      info.name,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Sp.md),
              Text(
                '${s['classLabel']!} ${_n(info.schoolClass)} · '
                '${_n(info.chapters)} ${s['chaptersLabel']!} · '
                '${_n(info.opened)} ${s['openedLabel']!}',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: Sp.lg),
        AnimatedProgress(
          value: progress,
          color: accent,
          countLabel: '${s['progressLabel']!} ${(progress * 100).round()}%',
        ),
        const SizedBox(height: Sp.xl),
        if (info.chapters == 0)
          Text(s['noChapters']!, style: Theme.of(context).textTheme.bodyMedium)
        else
          _ActionCard(
            icon: Icons.list_alt_outlined,
            title: s['openChapters']!,
            accent: accent,
            onTap:
                onOpenChapters ??
                () => context.go('/home/subjects/${info.subjectId}/chapters'),
          ),
        const SizedBox(height: Sp.md),
        _ActionCard(
          icon: Icons.search,
          title: s['openGuide']!,
          accent: accent,
          onTap:
              onOpenGuide ??
              () => context.go('/search-flow?subject=${info.subjectId}'),
        ),
        const SizedBox(height: Sp.md),
        _ActionCard(
          icon: Icons.fitness_center,
          title: s['openPractice']!,
          accent: accent,
          onTap: onOpenPractice ?? () => context.go('/practice'),
        ),
      ],
    );
  }

  String _n(int v) => numStr(v, bn);
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.accent,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      accent: accent,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(Sp.lg),
        child: Row(
          children: [
            Icon(icon, color: accent, size: IconSize.md),
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
