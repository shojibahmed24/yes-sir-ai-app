// Voice tutor hero: the one place the mic state, the remaining
// minutes (or the live call clock) and the honest status note sit,
// on the app gradient. Text is white/white70 only (WCAG AA on the
// deep stops); the caller decides every string.
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';

class VoiceHero extends StatelessWidget {
  const VoiceHero({
    super.key,
    required this.title,
    required this.status,
    required this.micOn,
    required this.note,
    this.big = false,
  });
  final String title;
  final String status;
  final bool micOn;
  final String note;

  /// True while a call runs: the status is the clock (displayLarge).
  final bool big;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      key: const Key('voice-hero'),
      width: double.infinity,
      padding: const EdgeInsets.all(Sp.xl),
      decoration: BoxDecoration(
        gradient: dark ? AppTheme.heroGradientDark : AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(Rad.xl),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Sp.lg),
          CircleAvatar(
            radius: 56,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            child: Icon(
              micOn ? Icons.mic : Icons.mic_none,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: Sp.md),
          Text(
            status,
            style:
                (big
                        ? Theme.of(context).textTheme.displayLarge
                        : Theme.of(context).textTheme.headlineMedium)
                    ?.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: Sp.xs),
            Text(
              note,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
