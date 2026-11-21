// Lesson hub building blocks (B12), split out so lesson_hub_screen
// stays under the 250-line cap. Pure presentation: the screen decides
// which types to offer from the server counts.
import 'package:flutter/material.dart';

import '../../../theme/animated_card.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../search_flow_types.dart';
import 'digits.dart';

/// Label/colour/icon for the three question-type cards.
class LessonHubTypeStyle {
  const LessonHubTypeStyle({
    required this.icon,
    required this.titleKey,
    required this.subKey,
    required this.accent,
  });
  final IconData icon;
  final String titleKey;
  final String subKey;
  final Color accent;

  static LessonHubTypeStyle of(SearchFlowType t) {
    switch (t) {
      case SearchFlowType.mcq:
        return const LessonHubTypeStyle(
          icon: Icons.quiz_outlined,
          titleKey: 'mcq',
          subKey: 'mcqSub',
          accent: AppTheme.primary,
        );
      case SearchFlowType.creative:
        return const LessonHubTypeStyle(
          icon: Icons.edit_note_rounded,
          titleKey: 'creative',
          subKey: 'creativeSub',
          accent: AppTheme.secondary,
        );
      default:
        return const LessonHubTypeStyle(
          icon: Icons.short_text_rounded,
          titleKey: 'short',
          subKey: 'shortSub',
          accent: AppTheme.success,
        );
    }
  }
}

class LessonHubHeader extends StatelessWidget {
  const LessonHubHeader({
    super.key,
    required this.subject,
    required this.chapter,
    required this.title,
    required this.chapterLabel,
    required this.bn,
  });
  final String subject;
  final int chapter;
  final String title;
  final String chapterLabel;
  final bool bn;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Sp.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subject, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: Sp.xs),
            Text(
              '$chapterLabel ${numStr(chapter, bn)} · $title',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class LessonHubCard extends StatelessWidget {
  const LessonHubCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      accent: accent,
      onTap: onTap,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: accent.withValues(alpha: 0.14),
          child: Icon(icon, color: accent),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

/// A lesson whose guide prints no questions at all: say so and offer
/// the chapter-wide list instead of dead type cards.
class LessonHubEmpty extends StatelessWidget {
  const LessonHubEmpty({
    super.key,
    required this.s,
    required this.onAllLessons,
  });
  final Map<String, String> s;
  final VoidCallback onAllLessons;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Sp.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s['emptyTitle']!,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: Sp.xs),
            Text(s['emptyBody']!),
            const SizedBox(height: Sp.sm),
            ElevatedButton(
              onPressed: onAllLessons,
              child: Text(s['showAllLessons']!),
            ),
          ],
        ),
      ),
    );
  }
}
