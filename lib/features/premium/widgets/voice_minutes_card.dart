// Voice minutes card (S5.5): remaining monthly minutes as a ring, so
// the quota is visible before starting a session.
import 'package:flutter/material.dart';
import '../../../theme/app_tokens.dart';

class VoiceMinutesCard extends StatelessWidget {
  const VoiceMinutesCard({
    super.key,
    required this.remaining,
    required this.cap,
    required this.label,
    required this.unit,
  });
  final int remaining;
  final int cap;
  final String label;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final pct = cap <= 0 ? 0.0 : (remaining / cap).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Sp.md),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: pct,
                    strokeWidth: 5,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                  Text(
                    '$remaining',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: Sp.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleSmall),
                Text(
                  '$remaining/$cap $unit',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
