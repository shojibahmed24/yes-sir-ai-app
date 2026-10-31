// Guide availability flags for subject lists, split out to keep
// books_service.dart under the 250-line cap. Used by
// BooksService.subjectsAsync: locked subjects (no supplied
// textbook) get hasGuide/guideChapterCount from the server, so
// Home and Search can source subjects from the guide as well as
// from textbooks, for every class.
import '../models/backend_models.dart';
import 'guide_bank_service.dart';

/// Guide enrichment for locked subjects only. Unlocked subjects
/// already show via their textbook and need no check. Each check
/// is one Edge guideChapters call, capped at 8s; a null or empty
/// result means "no guide" (never a guessed true). Any unexpected
/// failure returns the input list unchanged.
///
/// [GuideFlagsResult.complete] is false when ANY locked subject's
/// check failed or timed out (unknown, not "no guide"): callers
/// must NOT cache an incomplete result as if it were the server
/// truth — a partial snapshot cached once would keep shadowing
/// the real server count until the TTL expired (Step-4 fix for
/// the home tile showing a stale guide chapter count).
class GuideFlagsResult {
  const GuideFlagsResult({required this.subjects, required this.complete});
  final List<SubjectInfo> subjects;
  final bool complete;
}

Future<GuideFlagsResult> withGuideFlags(
  List<SubjectInfo> list,
  int schoolClass,
) async {
  final locked = list.where((s) => s.locked).toList();
  if (locked.isEmpty) return GuideFlagsResult(subjects: list, complete: true);
  try {
    final results = await Future.wait(
      locked.map((s) async {
        try {
          final chapters = await guideBankService
              .fetchGuideChapters(s.id, schoolClass: schoolClass)
              .timeout(const Duration(seconds: 8), onTimeout: () => null);
          return MapEntry(s.id, chapters);
        } catch (_) {
          return MapEntry(s.id, null);
        }
      }),
    );
    final complete = results.every((e) => e.value != null);
    final counts = <String, int>{};
    for (final e in results) {
      final c = e.value;
      if (c != null && c.isNotEmpty) counts[e.key] = c.length;
    }
    if (counts.isEmpty) {
      return GuideFlagsResult(subjects: list, complete: complete);
    }
    return GuideFlagsResult(
      subjects: list
          .map((s) => counts.containsKey(s.id)
              ? SubjectInfo(
                  id: s.id,
                  nameBn: s.nameBn,
                  nameEn: s.nameEn,
                  locked: s.locked,
                  chapterCount: s.chapterCount,
                  hasGuide: true,
                  guideChapterCount: counts[s.id]!,
                )
              : s)
          .toList(),
      complete: complete,
    );
  } catch (_) {
    return GuideFlagsResult(subjects: list, complete: false);
  }
}
