import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:yes_sir_ai/core/models/backend_models.dart';
import 'package:yes_sir_ai/theme/app_theme.dart';
import 'package:yes_sir_ai/theme/app_tokens.dart';

// R6: darker green for the letter circle (white on success ~3.4:1; on #1E7A4C ~5.3:1).
const _successDark = AppTheme.successDark;

/// Shared small cards for practice / quiz / model-test screens.
/// Warm Paper Scholar: cream card, rounded 24, soft shadow.
class PracticeCard extends StatelessWidget {
  const PracticeCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.onTap,
    this.maxTitleLines,
  });
  final String title;
  final int? maxTitleLines;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    // H4 FIX: the trailing button used to take its full intrinsic width
    // (theme minimumSize is Size.fromHeight(56), i.e. unbounded width),
    // so on a 360px phone at 1.25x font scale it squeezed the Expanded
    // title column below one Bangla word's width and Flutter broke the
    // title character-by-character (দৈ / নি / ক / কুই / জ), growing
    // the card to 5+ lines. Capping the trailing slot guarantees the
    // title column stays wider than one word; maxLines + ellipsis
    // bounds the card height even if a word still has to split.
    // 360px math: 360 - 32 (ListView) - 32 (card padding) - 52 (icon
    // + gap) - 12 (gap) - 150 (trailing cap) = 82px for the title,
    // vs 'দৈনিক' at 20sp x 1.25 = ~65-75px, so it wraps at the word
    // boundary into 2 lines. No-icon cards get 144px; the cap also
    // bounds every other PracticeCard trailing button (model-test
    // results 'আবার পড়ো', practice-tab 'শুরু করো', saved questions).
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (icon != null)
                CircleAvatar(
                  backgroundColor: AppTheme.primary,
                  child: Icon(icon, color: Colors.white),
                ),
              if (icon != null) const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: maxTitleLines ?? 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              if (trailing != null) const SizedBox(width: 12),
              if (trailing != null)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: trailing!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class OptionTile extends StatefulWidget {
  const OptionTile({
    super.key,
    required this.label,
    required this.text,
    required this.selected,
    this.correct,
    this.onTap,
  });
  final String label;
  final String text;
  final bool selected;
  final bool? correct;
  final VoidCallback? onTap;
  @override
  State<OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<OptionTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _feedback;
  bool _pressed = false;
  @override
  void initState() {
    super.initState();
    _feedback = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void didUpdateWidget(OptionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Feedback fires once, when checking reveals the result:
    // correct = small pop, wrong + selected = small red shake.
    // Reduced Motion: no feedback animation at all.
    final revealed = oldWidget.correct == null && widget.correct != null;
    final feedbackTile =
        widget.correct == true || (widget.correct == false && widget.selected);
    if (revealed && feedbackTile && !MediaQuery.of(context).disableAnimations) {
      _feedback.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _feedback.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // H2: pre-check selected state is PRIMARY (blue) — never green/red,
    // so it cannot be mistaken for correct/wrong. Post-check rendering
    // below is unchanged: green = correct, red = wrong + selected.
    final isChecked = widget.correct != null;
    final isSelectedPre = widget.selected && !isChecked;
    final isWrongSelected =
        isChecked && widget.correct == false && widget.selected;
    Color? bg;
    // Unchecked options: soft blue chip, dark-blue letter.
    Color avatarColor = AppTheme.primary.withValues(alpha: 0.14);
    BorderSide? border;
    if (widget.correct == true) {
      bg = AppTheme.success.withValues(alpha: 0.15);
      avatarColor = _successDark;
      border = const BorderSide(color: AppTheme.success, width: 2);
    } else if (isWrongSelected) {
      bg = AppTheme.error.withValues(alpha: 0.15);
      avatarColor = AppTheme.errorDark;
      border = const BorderSide(color: AppTheme.error, width: 2);
    } else if (isSelectedPre) {
      bg = AppTheme.primary.withValues(alpha: 0.15);
      avatarColor = AppTheme.primary;
      border = const BorderSide(color: AppTheme.primary, width: 2);
    }
    final scheme = Theme.of(context).colorScheme;
    final letter = bg != null
        ? Colors.white
        : (Theme.of(context).brightness == Brightness.dark
              ? scheme.primary
              : AppTheme.primaryDark);
    final card = Card(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Rad.md),
        side: border ?? BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap: widget.onTap,
        onTapDown: (_) {
          if (!MediaQuery.of(context).disableAnimations) {
            setState(() => _pressed = true);
          }
        },
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        borderRadius: BorderRadius.circular(Rad.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: avatarColor,
                child: Text(
                  widget.label,
                  style: TextStyle(color: letter, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.text,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (isSelectedPre)
                const Icon(Icons.radio_button_checked, color: AppTheme.primary),
              if (widget.correct == true)
                const Icon(Icons.check_circle, color: AppTheme.success),
              if (isWrongSelected)
                const Icon(Icons.cancel, color: AppTheme.error),
            ],
          ),
        ),
      ),
    );
    return AnimatedBuilder(
      animation: _feedback,
      builder: (context, child) {
        final t = _feedback.value;
        final shake = isWrongSelected
            ? math.sin(t * math.pi * 4) * (1 - t) * 4
            : 0.0;
        final pop = widget.correct == true
            ? 1 + 0.03 * math.sin(t * math.pi)
            : 1.0;
        return Transform.translate(
          offset: Offset(shake, 0),
          child: AnimatedScale(
            scale: _pressed ? 0.97 : pop,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: child,
          ),
        );
      },
      child: card,
    );
  }
}

class ScoreHeader extends StatelessWidget {
  const ScoreHeader({
    super.key,
    required this.score,
    required this.total,
    required this.message,
  });
  final String score;
  final String total;
  final String message;
  @override
  Widget build(BuildContext context) {
    return Card(
      // D1+D2: primaryDark #1E4FBF, white text ~7.2:1. The total
      // line is pure white too — white70 here would be ~4.4:1.
      color: AppTheme.primaryDark,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              score,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(total, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.value});
  final double value;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 8,
        backgroundColor: AppTheme.inkMuted.withValues(alpha: 0.3),
        color: AppTheme.amber,
      ),
    );
  }
}

/// Question card shared by the quiz and model-test exam
/// screens (Phase-5): the question text, plus a small note
/// when the item accepts more than one answer — the student
/// must know before choosing, not only on the results screen.
class QuizQuestionCard extends StatelessWidget {
  const QuizQuestionCard({
    super.key,
    required this.item,
    required this.bangla,
    required this.hint,
  });
  final QuizItem item;
  final bool bangla;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final multiKey = item.correctIndices.length > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              bangla ? item.questionBn : item.questionEn,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
        if (multiKey) ...[
          const SizedBox(height: 8),
          Text(hint, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}
