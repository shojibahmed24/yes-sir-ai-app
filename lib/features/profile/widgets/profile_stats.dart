// Profile stat card (streak / medals), extracted from the profile
// screen to keep that file under the 250-line cap. The icon carries
// its own accent so the two stats read differently at a glance.
import 'package:flutter/material.dart';

import '../../../theme/app_tokens.dart';

class ProfileStatCard extends StatelessWidget {
  const ProfileStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Sp.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Rad.md),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: Sp.sm),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
