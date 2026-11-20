// Read-only hero band for the parent dashboard: the student heading
// on the app gradient. No actions, no numbers — the stat cards below
// carry the data.
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';

class ParentHero extends StatelessWidget {
  const ParentHero({
    super.key,
    required this.heading,
    required this.name,
    required this.schoolClass,
  });
  final String heading;
  final String name;
  final String schoolClass;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Sp.xl),
      decoration: BoxDecoration(
        gradient: dark ? AppTheme.heroGradientDark : AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(Rad.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
          if (name.isNotEmpty)
            Text(name, style: const TextStyle(color: Colors.white70)),
          if (schoolClass.isNotEmpty)
            Text(
              (name.isEmpty ? '' : '· ') + schoolClass,
              style: const TextStyle(color: Colors.white70),
            ),
        ],
      ),
    );
  }
}
