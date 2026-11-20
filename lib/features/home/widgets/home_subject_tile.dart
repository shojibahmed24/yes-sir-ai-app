import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/animated_card.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../home_design.dart';

/// Destination for a home subject tile: ALWAYS the new search
/// flow, with the tapped subject preselected (Step 4). The old
/// guide-only branch (/guide-chapters) is gone: guide-only tiles
/// land on the search screen too, which defaults their source to
/// guide because the textbook is locked.
String homeSubjectRoute(String subjectId) => '/search-flow?subject=$subjectId';

/// One subject tile on Home. Tapping goes to the new search
/// flow with this subject preselected (guide-only or not: the
/// search screen picks the default source from the lock state).
/// Uses the ONE shared card style (AnimatedCard: tap scale +
/// entrance) with the subject's own colour and glyph.
class HomeSubjectTile extends StatelessWidget {
  const HomeSubjectTile({
    super.key,
    required this.name,
    required this.chaptersLabel,
    this.subjectId = 'math',
  });
  final String name;
  final String chaptersLabel;
  final String subjectId;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppTheme.subjectColorFor(subjectId, dark: dark);
    return AnimatedCard(
      accent: accent,
      radius: HomeDesign.cardRadius,
      onTap: () => context.go(homeSubjectRoute(subjectId)),
      child: Padding(
        padding: const EdgeInsets.all(Sp.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(Sp.sm),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(Rad.sm),
              ),
              child: Icon(
                subjectIconFor(subjectId),
                size: IconSize.lg,
                color: accent,
              ),
            ),
            const SizedBox(height: Sp.sm),
            // Name wraps (never truncates) and the grid row sizes to
            // the tallest tile, so no text can paint outside a card
            // even at 1.3x font scale.
            Text(name, style: Theme.of(context).textTheme.headlineMedium),
            Text(chaptersLabel, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
