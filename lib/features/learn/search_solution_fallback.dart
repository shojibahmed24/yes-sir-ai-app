// Exact-answer fallback for the textbook search screen: the chapter
// exists check and the lesson / chapter-list / honest no-match
// decision. Extracted from search_screen.dart to keep that file
// under the 250-line cap. Behavior is unchanged — the same
// decideSearchShortcut call, the same three destinations.
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/books_service.dart';
import 'lesson_selection.dart';

Future<void> resolveSearchFallback({
  required BuildContext context,
  required String subject,
  required int schoolClass,
  required int chapter,
  required int page,
  required int problem,
  required String label,
  required bool bn,
  required void Function(int? bannerPage) goChapterList,
}) async {
  List<dynamic>? chapters;
  try {
    chapters = await booksService.chaptersForSubjectAsync(
      schoolClass,
      subject,
      bn,
    );
  } catch (_) {
    chapters = null;
  }
  if (!context.mounted) return;
  final chapterExists =
      chapters == null || chapters.any((c) => c.number == chapter);
  switch (decideSearchShortcut(
    // Reached only after the exact resolve returned not-found.
    exactFound: false,
    chapterExists: chapterExists,
  )) {
    case SearchShortcut.lesson:
      context.go('/lesson');
      break;
    case SearchShortcut.chapterList:
      goChapterList(page);
      break;
    case SearchShortcut.noMatch:
      LessonSelectionHolder.set(
        LessonSelection(
          subject: subject,
          chapter: chapter,
          page: page,
          problem: problem,
          queryText: label,
          schoolClass: schoolClass,
        ),
      );
      context.go('/lesson/no-match');
      break;
  }
}
