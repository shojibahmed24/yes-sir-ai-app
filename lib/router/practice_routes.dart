import 'package:go_router/go_router.dart';
import '../core/widgets/back_scope.dart';
import '../features/practice/practice_screen.dart';
import '../features/practice/quiz_question_screen.dart';
import '../features/practice/quiz_results_screen.dart';
import '../features/practice/model_test_list_screen.dart';
import '../features/practice/model_test_exam_screen.dart';
import '../features/practice/model_test_results_screen.dart';
import '../features/practice/test_review_screen.dart';
import '../features/practice/widgets/review_filter_cards.dart';
import '../features/progress/progress_screen.dart';
import '../features/progress/achievements_screen.dart';
import '../features/progress/saved_questions_screen.dart';

// Practice + Books + Progress routes, verified against screen headers.
final List<GoRoute> practiceRoutes = [
  GoRoute(
    path: '/practice',
    builder: (c, s) =>
        BackScope(parent: '/home', child: const PracticeScreen()),
  ),
  GoRoute(path: '/practice-tab', redirect: (c, s) => '/practice'),
  GoRoute(
    path: '/quiz',
    builder: (c, s) =>
        BackScope(parent: '/practice', child: const QuizQuestionScreen()),
  ),
  GoRoute(
    path: '/quiz-results',
    builder: (c, s) =>
        BackScope(parent: '/practice', child: const QuizResultsScreen()),
  ),
  GoRoute(
    path: '/model-tests',
    builder: (c, s) =>
        BackScope(parent: '/practice', child: const ModelTestListScreen()),
  ),
  GoRoute(
    path: '/model-test-exam',
    builder: (c, s) =>
        BackScope(parent: '/model-tests', child: const ModelTestExamScreen()),
  ),
  GoRoute(
    path: '/model-test-results',
    builder: (c, s) => BackScope(
      parent: '/model-tests',
      child: const ModelTestResultsScreen(),
    ),
  ),
  GoRoute(
    path: '/test-review',
    builder: (c, s) {
      final raw = s.uri.queryParameters['filter'] ?? 'wrong';
      final filter = ReviewFilter.values.firstWhere(
        (f) => f.name == raw,
        orElse: () => ReviewFilter.wrong,
      );
      return BackScope(
        parent: '/model-test-results',
        child: TestReviewScreen(filter: filter),
      );
    },
  ),
  // Guide-only app (round 4): the textbook library and page reader are
  // unreachable. The files stay on disk (never delete); the routes
  // send old links to the guide search flow.
  GoRoute(path: '/books', redirect: (c, s) => '/search-flow'),
  GoRoute(path: '/books/viewer', redirect: (c, s) => '/search-flow'),
  // Back-compat for links built before the guide-only switch.
  GoRoute(path: '/lesson', redirect: (c, s) => '/search-flow'),
  GoRoute(path: '/chapters', redirect: (c, s) => '/search-flow'),
  GoRoute(path: '/search', redirect: (c, s) => '/search-flow'),
  GoRoute(
    path: '/progress',
    builder: (c, s) =>
        BackScope(parent: '/home', child: const ProgressScreen()),
  ),
  GoRoute(
    path: '/achievements',
    builder: (c, s) =>
        BackScope(parent: '/progress', child: const AchievementsScreen()),
  ),
  GoRoute(
    path: '/saved',
    builder: (c, s) =>
        BackScope(parent: '/profile', child: const SavedQuestionsScreen()),
  ),
];
