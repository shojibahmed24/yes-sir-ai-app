// Results celebration ring: one animated ring for a quiz score.
// Colour reads the score (>=80 success, >=50 primary, else error)
// and Reduced Motion shows the final ring immediately.
import 'package:flutter/material.dart';

import '../../../theme/animated_progress.dart';
import '../../../theme/app_theme.dart';

class ScoreRing extends StatelessWidget {
  const ScoreRing({super.key, required this.percent, this.size = 84});
  final int percent;
  final double size;

  Color _color() {
    if (percent >= 80) return AppTheme.success;
    if (percent >= 50) return AppTheme.primary;
    return AppTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedProgress(
      value: percent / 100,
      ring: true,
      size: size,
      color: _color(),
    );
  }
}
