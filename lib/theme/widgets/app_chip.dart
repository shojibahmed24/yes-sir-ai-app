// Reusable chip for status / type / filter labels. A tiny leading
// icon is optional; [selected] turns on the accent fill so a chip
// can double as a selectable filter. Colour falls back to the theme
// primary when no [accent] is given.
import 'package:flutter/material.dart';

import '../app_tokens.dart';

class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.icon,
    this.accent,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final Color? accent;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accent ?? theme.colorScheme.primary;
    final fill = selected ? color : Colors.transparent;
    final fg = selected ? theme.colorScheme.onPrimary : color;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: IconSize.sm, color: fg),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: fg,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(Rad.pill),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: content,
    );

    if (onTap == null) return chip;
    return InkWell(
      borderRadius: BorderRadius.circular(Rad.pill),
      onTap: onTap,
      child: chip,
    );
  }
}
