// Subject-scoped quiz pool (round 3, quiz plan).
//
// The app had three separate MCQ paths: guide questions, the local
// bank, and model-test sets. A subject's quiz only ever saw the guide
// path, so a chapter whose guide has no MCQ looked empty even when the
// same subject's bank had MCQs.
//
// This registry keeps quizzes SUBJECT-WISE (math never mixes with
// science) but fills one subject's set from every source that belongs
// to that subjects:
//   1. the guide's keyed MCQs (exact grounding, preferred)
//   2. the same subject's bank MCQs (local, instant)
//   3. model-test set MCQs (already resolved by their own service)
//
// Order is preserved (guide first), nothing is duplicated, and the
// caller is told whether the bank filled a shortfall so the UI can say
// it honestly.
import '../../core/models/backend_models.dart';
import '../../core/services/guide_quiz_service.dart';

/// A subject's assembled quiz + how it was filled.
class SubjectQuizPool {
  const SubjectQuizPool({
    required this.items,
    required this.guideCount,
    required this.bankCount,
  });

  final List<QuizItem> items;
  final int guideCount;
  final int bankCount;

  bool get usedBank => bankCount > 0;
  bool get isEmpty => items.isEmpty;
}

/// Source seams so tests can drive this without the network.
typedef GuidePoolFetcher = Future<List<QuizItem>> Function();
typedef SetPoolFetcher = Future<List<QuizItem>> Function();
typedef BankPoolFetcher = List<QuizItem> Function();

/// Builds one subject's quiz of at most [count] items.
///
/// Guide first, then the same subject's bank ([bankFetcher] must be
/// scoped by the caller to that subject) up to [count]; set items are
/// appended only when [setFetcher] is given (model-test start).
/// Duplicates by question id are dropped, so a row that appears in two
/// sources is asked once.
Future<SubjectQuizPool> buildSubjectQuizPool({
  required String subject,
  required int count,
  String? seedKey,
  Duration guideTimeout = const Duration(seconds: 5),
  Duration setTimeout = const Duration(seconds: 8),
  GuidePoolFetcher? guideFetcher,
  BankPoolFetcher? bankFetcher,
  SetPoolFetcher? setFetcher,
}) async {
  final guide = <QuizItem>[];
  if (guideFetcher != null) {
    try {
      guide.addAll(await guideFetcher().timeout(guideTimeout));
    } catch (_) {
      // A slow/failed guide call must not empty the quiz.
    }
  }
  final seen = <String>{};
  final out = <QuizItem>[];
  void add(QuizItem item) {
    if (out.length >= count) return;
    if (!seen.add(item.id)) return;
    out.add(item);
  }

  for (final item in guide) {
    add(item);
  }
  final guideCount = out.length;

  // Same subject only: the caller scopes the bank pool to the subject
  // being quizzed, so math questions can never reach a science quiz.
  var bankCount = 0;
  if (out.length < count && bankFetcher != null) {
    for (final item in bankFetcher()) {
      if (out.length >= count) break;
      final before = out.length;
      add(item);
      if (out.length > before) bankCount++;
    }
  }

  if (out.length < count && setFetcher != null) {
    try {
      final extra = await setFetcher().timeout(setTimeout);
      for (final item in extra) {
        add(item);
      }
    } catch (_) {
      // Set MCQs are a bonus: never a failure state.
    }
  }
  return SubjectQuizPool(
    items: out,
    guideCount: guideCount,
    bankCount: bankCount,
  );
}

/// The guide limit a full daily quiz aims for.
const kQuizTargetCount = GuideQuizService.quizLimit;
