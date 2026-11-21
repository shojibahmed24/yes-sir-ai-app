import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/profile_service.dart';
import '../../../theme/animated_card.dart';
import '../../../theme/app_theme.dart';
import 'mock_data.dart';

/// Chapter row. Tapping sets the selection (this subject + chapter)
/// and opens Search with that chapter pre-selected — it no longer
/// drops the subject and lands on a generic search.
class ChapterCard extends StatelessWidget {
  const ChapterCard({
    super.key,
    required this.chapter,
    required this.bn,
    required this.statusLabel,
    required this.pagesLabel,
    this.subjectId = 'math',
    this.chapterNumber = 1,
  });
  final MockChapter chapter;
  final bool bn;
  final String statusLabel;
  final String pagesLabel;
  final String subjectId;
  final int chapterNumber;

  IconData get _icon {
    switch (chapter.status) {
      case 'done':
        return Icons.check_circle;
      case 'inProgress':
        return Icons.timelapse;
      default:
        return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    // UI palette (গ): the leading icon carries the subject colour
    // (done stays green). ONE card style app-wide (AnimatedCard).
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = chapter.status == 'done'
        ? AppTheme.success
        : AppTheme.subjectColorFor(subjectId, dark: dark);
    return AnimatedCard(
      accent: accent,
      onTap: () async {
        // Real navigation: the search flow opens with this chapter
        // pre-picked. The old path stamped page 45 / problem 5 (demo
        // defaults) and opened the legacy /search stepper.
        final schoolClass = await profileService.loadSchoolClass();
        if (!context.mounted) return;
        final cls = schoolClass == null ? '' : '&class=$schoolClass';
        context.go(
          '/search-flow?subject=$subjectId$cls&chapter=$chapterNumber',
        );
      },
      child: ListTile(
        leading: Icon(_icon, color: accent),
        title: Text(
          bn ? chapter.bn : chapter.en,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          chapter.pages.isEmpty
              ? statusLabel
              : '$pagesLabel ${chapter.pages} · $statusLabel',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
