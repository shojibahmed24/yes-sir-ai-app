// Board creative row in board format: board/year label, stimulus
// box, then ক/খ/গ/ঘ with their printed marks. Falls back to the
// full question text when the printed shape is not the 4-part
// pattern (the caller may also choose the normal row).
import 'package:flutter/material.dart';

import '../../../core/models/guide_bank_model.dart';
import '../../../theme/app_tokens.dart';
import '../../../theme/widgets/marks_badge.dart';
import '../board_creative_parse.dart';

class BoardCreativeCard extends StatelessWidget {
  const BoardCreativeCard({
    super.key,
    required this.question,
    required this.locked,
    required this.s,
    required this.onTap,
    this.boardLabel,
  });

  final GuideBankQuestion question;
  final bool locked;
  final Map<String, String> s;
  final VoidCallback onTap;
  final String? boardLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parsed = parseBoardCreative(question.questionText);
    final body = question.questionText;
    final parts = parsed?.parts ?? const <BoardCreativePart>[];
    final marks = question.marksParts;
    final canMark = marks != null && marks.length == parts.length;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(Rad.xl),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Sp.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: Sp.sm,
                runSpacing: Sp.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (boardLabel != null) Chip(label: Text(boardLabel!)),
                  if (locked) const Icon(Icons.lock_outline, size: 18),
                  if (question.marks != null)
                    Chip(label: Text('${question.marks} ${s['marksWord']!}')),
                ],
              ),
              const SizedBox(height: Sp.sm),
              if (parsed == null)
                Text(body, style: theme.textTheme.bodyMedium)
              else ...[
                if (parsed.stimulus.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(Sp.md),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(Rad.md),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['stimulusTitle']!,
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: Sp.xs),
                        Text(
                          parsed.stimulus,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: Sp.sm),
                for (var i = 0; i < parts.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Sp.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          child: Text(
                            parts[i].label,
                            style: theme.textTheme.labelMedium,
                          ),
                        ),
                        const SizedBox(width: Sp.sm),
                        Expanded(
                          child: Text(
                            parts[i].text,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        if (canMark) ...[
                          const SizedBox(width: Sp.sm),
                          MarksBadge(label: '${marks[i]}'),
                        ],
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
