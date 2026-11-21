// Home's data in one load, from the same stores every other
// screen reads — never hardcoded, never a second copy.
// Batch 2, item 3:
//   lessonsToday  — LearnStore (lesson opens recorded today; 0 on
//                   a fresh install or a new day).
//   chaptersOpened— LearnStore distinct chapter keys opened. This
//                   is OPENED, not finished: no chapter-completion
//                   event exists anywhere in the codebase, so the
//                   Home label was corrected to "opened" instead of
//                   claiming "finished" (see home_strings).
//   savedCount    — LocalStore.savedQuestions(), the SAME list the
//                   Saved screen and Profile read. LearnStore's own
//                   area2_saved_ids diverges from it: quiz saves
//                   write only saved_questions, and Saved-screen
//                   unsaves remove only from saved_questions, so
//                   the area2 count under/over-counted vs Saved.
//   schoolClass   — profileService.loadSchoolClass(), the single
//                   class source Settings also reads.
import '../../core/services/local_store.dart';
import '../../core/services/profile_service.dart';
import '../../core/services/progress_service.dart';
import '../learn/learn_store.dart';

class HomeData {
  const HomeData({
    required this.summary,
    required this.savedCount,
    required this.schoolClass,
    required this.progress,
    required this.opened,
  });
  final LearnSummary summary;
  final int savedCount;
  final int? schoolClass;

  /// Real streak / xp / goal / weak chapters / week activity (D1–D4).
  final ProgressSummary progress;

  /// Class-stamped chapter keys — per-subject progress % (D5).
  final List<String> opened;
}

Future<HomeData> loadHomeData() async {
  final results = await Future.wait([
    LearnStore.summary(),
    LocalStore.savedQuestions(),
    profileService.loadSchoolClass(),
    progressService.summary(),
    LearnStore.chaptersList(),
  ]);
  final saved = results[1] as List<String>;
  return HomeData(
    summary: results[0] as LearnSummary,
    savedCount: saved.length,
    schoolClass: results[2] as int?,
    progress: results[3] as ProgressSummary,
    opened: results[4] as List<String>,
  );
}
