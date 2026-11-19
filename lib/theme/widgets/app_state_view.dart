// Shared full-surface state (empty / error / loading) used by any
// screen instead of each screen hand-rolling its own "nothing here".
// Empty/error show a glyph + title + optional body + one action;
// loading shows a spinner (+ optional title). Nothing here invents
// content — labels come from the caller (page-wise l10n).
import 'package:flutter/material.dart';

import '../app_tokens.dart';

enum AppStateKind { empty, error, loading }

class AppStateView extends StatelessWidget {
  const AppStateView({
    super.key,
    required this.kind,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.icon,
  });

  final AppStateKind kind;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    final Widget content;
    if (kind == AppStateKind.loading) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: IconSize.lg,
            height: IconSize.lg,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: Sp.md),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          ),
        ],
      );
    } else {
      final glyph =
          icon ??
          (kind == AppStateKind.error
              ? Icons.error_outline
              : Icons.inbox_outlined);
      content = Padding(
        padding: const EdgeInsets.all(Sp.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(glyph, size: IconSize.xl, color: muted),
            const SizedBox(height: Sp.md),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (message != null && message!.isNotEmpty) ...[
              const SizedBox(height: Sp.sm),
              Text(
                message!,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: Sp.lg),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      );
    }

    // Center when there is room, scroll when the caller gives a tight
    // height (e.g. a fixed-height placeholder) — never overflow.
    return LayoutBuilder(
      builder: (context, constraints) {
        // minHeight only when the caller bounds the height; an
        // unbounded parent (scroll view) leaves centring to the child.
        final minHeight =
            constraints.hasBoundedHeight ? constraints.maxHeight : 0.0;
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Center(child: content),
          ),
        );
      },
    );
  }
}
