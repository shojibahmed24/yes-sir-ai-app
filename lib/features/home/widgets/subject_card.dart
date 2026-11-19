import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';

/// Subject card on SubjectsScreen. Locked subjects show the locked
/// message and do NOT navigate to chapters (book not supplied yet).
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
    // UI palette (গ): subject-colour accent dot + progress bar;
    // locked cards keep the muted lock look, no colour tease.
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = locked
        ? AppTheme.inkMuted
        : AppTheme.subjectColorFor(subjectId, dark: dark);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(Rad.xl),
        onTap: locked
            ? null
            : () => context.go('/home/subjects/$subjectId/chapters'),
        child: Padding(
          padding: const EdgeInsets.all(Sp.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: Sp.sm),
                  Expanded(
                    child: Text(
                      name,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  if (locked) Icon(Icons.lock_outlined, color: muted),
                ],
              ),
              const SizedBox(height: Sp.xs),
              Text(
                '$chapters $chaptersLabel',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              // "Book not supplied yet" is information, not an error:
              // muted ink, never the red error colour.
              if (locked) Text(lockedLabel, style: TextStyle(color: muted)),
              if (!locked) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(value: progress, color: accent),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
