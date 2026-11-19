// Board sub-section + Phase-3 lesson-hub routes. Split out of
// learn_routes.dart to keep that file under the 250-line cap.
import 'package:go_router/go_router.dart';

import '../core/widgets/back_scope.dart';
import '../features/learn/lesson_hub_screen.dart';
import '../features/learn/search_flow_board_sections.dart';

final List<GoRoute> lessonHubRoutes = [
  // Board sub-sections (Board revision 2026-11-02): the Board tile
  // lands here, never straight on a mixed list. returnTo lets the
  // lesson hub come back to itself.
  GoRoute(
    path: '/search-flow-board',
    builder: (c, s) {
      final q = s.uri.queryParameters;
      return BackScope(
        parent: q['returnTo'] ?? '/search-flow',
        child: SearchFlowBoardSectionsScreen(
          subjectId: q['subject'] ?? 'math',
          schoolClass: int.tryParse(q['class'] ?? '') ?? 6,
        ),
      );
    },
  ),
  // Phase 3 lesson hub: one lesson, content types separated.
  GoRoute(
    path: '/lesson-hub',
    builder: (c, s) {
      final q = s.uri.queryParameters;
      return BackScope(
        parent: q['returnTo'] ?? '/search-flow',
        child: LessonHubScreen(
          subjectId: q['subject'] ?? 'math',
          schoolClass: int.tryParse(q['class'] ?? '') ?? 6,
          chapter: int.tryParse(q['chapter'] ?? '') ?? 1,
          lesson: q['lesson'],
          lessonTitle: q['title'] ?? '',
        ),
      );
    },
  ),
];
