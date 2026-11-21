import 'package:flutter/material.dart';
import '../../../l10n/pages/chat_strings.dart';
import '../../../theme/app_theme.dart';
import 'solution_blocks.dart';

/// Chat bubble: AI on the left, user on the right. AI text goes
/// through the shared block renderer, so markdown from the AI
/// (**bold**, bullets, tables) renders as real formatting and
/// never prints raw *, ** or | markers. User-typed bubbles stay
/// plain Text, shown exactly as typed.
/// AI bubbles optionally carry a save toggle (persisted by the chat
/// screen); user bubbles never do. Colours are theme-aware: the
/// AI bubble uses the theme surface (light card in light mode,
/// dark slate in dark mode) and both texts use onSurface, so
/// dark mode never pairs forced ink with a dark background.
/// [fontSize] defaults to 15 so existing callers/tests keep
/// working; the chat screen's font control overrides it.
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.onSave,
    this.isSaved = false,
    this.saveLabel,
    this.fontSize = 15,
  });
  final String text;
  final bool isUser;
  final VoidCallback? onSave;
  final bool isSaved;
  final String? saveLabel;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    // UI palette (গ): user bubble blue (tint + blue border),
    // AI bubble cream/surface + subtle border. Reading text
    // stays onSurface in both modes. New messages slide in
    // (250ms fade + 8px rise); Reduced Motion shows them at once.
    final bubble = Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            // R12: 300dp fixed overflowed on 320dp-wide phones
            // (300 + padding > screen). 80% of the screen width
            // keeps the bubble inside on every width.
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isUser
                  ? AppTheme.primary.withValues(alpha: 0.18)
                  : Theme.of(context).colorScheme.surface,
              border: Border.all(
                color: isUser
                    ? AppTheme.primary.withValues(alpha: 0.30)
                    : onSurface.withValues(alpha: 0.15),
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: isUser
                ? Text(
                    text,
                    style: TextStyle(
                      fontSize: fontSize,
                      height: 1.6,
                      color: onSurface,
                    ),
                  )
                // SelectionArea: long-press copies an AI answer (no
                // clipboard button needed, and formatting is kept).
                : SelectionArea(
                    child: SolutionBlocks(text: text, fontSize: fontSize),
                  ),
          ),
          if (!isUser && onSave != null)
            TextButton.icon(
              onPressed: onSave,
              icon: Icon(
                isSaved ? Icons.bookmark : Icons.bookmark_border,
                size: 16,
              ),
              // M4: no hardcoded fallback — the chat screen passes
              // saveLabel; this locale-aware fallback only covers
              // callers that do not (e.g. tests).
              label: Text(
                saveLabel ??
                    (Localizations.localeOf(context).languageCode == 'bn'
                        ? chatStringsBn['saveQ']!
                        : chatStringsEn['saveQ']!),
              ),
            ),
        ],
      ),
    );
    if (MediaQuery.of(context).disableAnimations) return bubble;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - t)),
          child: child,
        ),
      ),
      child: bubble,
    );
  }
}
