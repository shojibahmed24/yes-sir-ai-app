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
  });
  final String subjectId;
  final String name;
  final int chapters;
  final int done;
  final bool locked;
  final String chaptersLabel;
  final String lockedLabel;

  @override
  Widget build(BuildContext context) {
    final progress = chapters == 0 ? 0.0 : done / chapters;
    // UI palette (গ): subject-colour accent + progress bar; locked
    // cards keep the muted lock look, no colour tease.
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = locked
        ? AppTheme.inkMuted
        : AppTheme.subjectColorFor(subjectId, dark: dark);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return AnimatedCard(
      accent: accent,
      radius: Rad.xl,
      onTap: locked ? null : () => context.go('/home/subjects/$subjectId'),
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
                if (locked) Icon(Icons.lock_outlined, color: muted),
              ],
            ),
            const SizedBox(height: Sp.sm),
            Text(
              '$chapters $chaptersLabel',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            // "Book not supplied yet" is information, not an error:
            // muted ink, never the red error colour.
            if (locked) Text(lockedLabel, style: TextStyle(color: muted)),
            if (!locked) ...[
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
