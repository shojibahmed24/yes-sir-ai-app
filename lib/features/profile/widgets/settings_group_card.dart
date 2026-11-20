// Shared Settings group card (UI polish 2026-11-20).
// ONE soft card per settings group: the title uses headlineMedium,
// the subtitle bodySmall, spacing/radius come from the theme
// tokens (Sp / Rad). Pure presentation — it owns no state and
// makes no storage calls, so SettingsScreen stays the only owner
// of what gets persisted.
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';

class SettingsGroupCard extends StatelessWidget {
  const SettingsGroupCard({
    super.key,
    this.title,
    this.subtitle,
    this.footnote,
    this.child,
    this.children = const [],
    this.accent,
  });

  final String? title;
  final String? subtitle;
  final String? footnote;
  final Widget? child;
  final List<Widget> children;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = Theme.of(context).textTheme;
    return SizedBox(
      width: double.infinity,
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(Rad.lg),
        // Ink (not a plain Container) so ListTile splashes stay visible
        // on the soft card, the same pattern AnimatedCard uses.
        child: Ink(
          decoration: AppTheme.softCardDecoration(
            accent: accent,
            dark: dark,
            radius: Rad.lg,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Sp.lg,
              vertical: Sp.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) Text(title!, style: text.headlineMedium),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: Sp.xs),
                    child: Text(subtitle!, style: text.bodySmall),
                  ),
                if (child != null) ...[const SizedBox(height: Sp.md), child!],
                ...children,
                if (footnote != null) ...[
                  const SizedBox(height: Sp.sm),
                  Text(footnote!, style: text.bodySmall),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
