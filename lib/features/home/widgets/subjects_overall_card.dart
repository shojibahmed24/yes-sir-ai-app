// Gradient "overall" band at the top of the Subjects hub. Deep
// gradient stops with white text only (WCAG AA on both themes) —
// the same hero pair Home uses, so the two screens read as one app.
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';

class SubjectsOverallCard extends StatelessWidget {
  const SubjectsOverallCard({
    super.key,
    required this.title,
    required this.booksLine,
    required this.lessonsLine,
  });
  final String title;
  final String booksLine;
  final String lessonsLine;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      key: const Key('subjects-hero'),
      width: double.infinity,
      padding: const EdgeInsets.all(Sp.xl),
      decoration: BoxDecoration(
        gradient: dark ? AppTheme.heroGradientDark : AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(Rad.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.30 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: Sp.xs),
          Text(booksLine, style: const TextStyle(color: Colors.white70)),
          Text(lessonsLine, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
