import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/animated_card.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../home_design.dart';

/// Subject card on SubjectsScreen. Locked subjects show the locked
/// message and do NOT navigate to chapters (book not supplied yet).
/// One card style app-wide: AnimatedCard (tap scale + entrance),
/// the subject's own colour and glyph, and a rounded progress bar.
class SubjectCard extends StatelessWidget {
  const SubjectCard({
    super.key,
    required this.name,
    required this.chapters,
    required this.done,
    required this.locked,
    required this.chaptersLabel,
    required this.lockedLabel,
    this.subjectId = 'math',
    this.guideOnly = false,
    this.guideLabel = '',
    this.hasGuide = false,
    this.badgeBook = '',
    this.badgeGuide = '',
    this.badgeBoth = '',
    this.sharedClass,
  });
  final String subjectId;
  final String name;
  final int chapters;
  final int done;
  final bool locked;

  /// Server-checked guide presence (works for unlocked subjects too,
  /// so a subject with both a textbook and a guide shows both).
  final bool hasGuide;

  /// Badge labels: what this subject actually has for this class.
  final String badgeBook;
  final String badgeGuide;
  final String badgeBoth;

  /// Class 10 reads the class-9 book/guide; the card says so instead
  /// of letting the student think these are class-10 books.
  final String? sharedClass;

  /// True for a subject with NO supplied textbook but a real guide: it
  /// stays usable and opens the guide search flow (guide-only launch).
  final bool guideOnly;
  final String guideLabel;
  final String chaptersLabel;
  final String lockedLabel;

  @override
  Widget build(BuildContext context) {
    final progress = chapters == 0 ? 0.0 : done / chapters;
    // UI palette (গ): subject-colour accent + progress bar; a truly
    // locked card (no book AND no guide) keeps the muted lock look.
    final dark = Theme.of(context).brightness == Brightness.dark;
    final inert = locked && !guideOnly;
    final accent = inert
        ? AppTheme.inkMuted
        : AppTheme.subjectColorFor(subjectId, dark: dark);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    // Honest source badge from server data, never a guess: book only,
    // guide only (no supplied textbook), or both.
    final badge = !hasGuide && !guideOnly
        ? (locked ? '' : badgeBook)
        : locked
        ? badgeGuide
        : badgeBoth;
    return AnimatedCard(
      accent: accent,
      radius: Rad.xl,
      onTap: inert
          ? null
          : guideOnly
          ? () => context.go('/search-flow?subject=$subjectId')
          : () => context.go('/home/subjects/$subjectId'),
      child: Padding(
        padding: const EdgeInsets.all(Sp.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(Sp.sm),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(Rad.sm),
                  ),
                  child: Icon(
                    subjectIconFor(subjectId),
                    size: IconSize.sm,
                    color: accent,
                  ),
                ),
                const SizedBox(width: Sp.md),
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                if (inert) Icon(Icons.lock_outlined, color: muted),
              ],
            ),
            const SizedBox(height: Sp.sm),
            Row(
              children: [
                if (badge.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Sp.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: inert ? 0.08 : 0.14),
                      borderRadius: BorderRadius.circular(Rad.sm),
                    ),
                    child: Text(
                      badge,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: inert ? muted : accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: Sp.sm),
                ],
                Expanded(
                  child: Text(
                    guideOnly ? guideLabel : '$chapters $chaptersLabel',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            // "Book not supplied yet" is information, not an error:
            // muted ink, never the red error colour.
            if (inert) Text(lockedLabel, style: TextStyle(color: muted)),
            if (sharedClass != null)
              Text(
                sharedClass!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: muted),
              ),
            if (!inert && !guideOnly) ...[
              const SizedBox(height: Sp.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(Rad.sm),
                child: LinearProgressIndicator(
                  value: progress,
                  color: accent,
                  minHeight: 6,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
