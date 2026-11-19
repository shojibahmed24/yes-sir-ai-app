// MCQ option card (ক/খ/গ/ঘ or A/B/C/D): leading letter badge +
// option text, tinted by state. Used by quiz, model test and any
// answer screen so the selected/correct/wrong look is identical.
import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../app_tokens.dart';

enum McqOptionState { idle, selected, correct, wrong }

class McqOptionCard extends StatelessWidget {
  const McqOptionCard({
    super.key,
    required this.label,
    required this.text,
    this.state = McqOptionState.idle,
    this.onTap,
    this.enabled = true,
  });

  final String label;
  final String text;
  final McqOptionState state;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _accentFor(context);
    final fill = enabled && state != McqOptionState.idle
        ? accent.withValues(alpha: 0.12)
        : theme.colorScheme.surface;
    final fg = enabled ? accent : theme.colorScheme.onSurfaceVariant;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: fill,
        borderRadius: BorderRadius.circular(Rad.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(Rad.md),
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Rad.md),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                _LetterBadge(label: label, color: fg),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: theme.textTheme.bodyMedium?.copyWith(color: fg),
                  ),
                ),
                if (state == McqOptionState.correct)
                  Icon(
                    Icons.check_circle_rounded,
                    size: IconSize.sm,
                    color: accent,
                  )
                else if (state == McqOptionState.wrong)
                  Icon(Icons.cancel_rounded, size: IconSize.sm, color: accent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _accentFor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (state) {
      case McqOptionState.correct:
        return AppTheme.success;
      case McqOptionState.wrong:
        return AppTheme.error;
      case McqOptionState.selected:
        return scheme.primary;
      case McqOptionState.idle:
        return scheme.onSurfaceVariant;
    }
  }
}

class _LetterBadge extends StatelessWidget {
  const _LetterBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.14),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
