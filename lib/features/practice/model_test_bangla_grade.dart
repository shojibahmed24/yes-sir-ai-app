// Bangla guide-set grade for a finished model test, split out of
// model_test_results_screen.dart for the 250-line cap.
//
// The grade is rendered ONLY when every input is genuine: a Bangla
// guide attempt (testId 'guide:<setId>'), grade bands from the sets
// action, printed per-row marks from the set rows, and a run that
// covers the bands' full scale (run max == bands' max). Anything
// missing, null, or mismatched returns null — a grade is never
// guessed. Saved-path revisits show none: skipped items are not
// stored, so the scale cannot be re-validated there.
import '../../core/models/backend_models.dart';
import '../practice/practice_store.dart';
import '../../core/services/guide_grade_bands.dart';
import '../../core/services/model_test_set_service.dart';
import '../../core/services/resolve_school_class.dart';

class RunGrade {
  const RunGrade(this.letter, this.total, this.max);
  final String letter;
  final int total, max;
}

Future<RunGrade?> loadBanglaGrade(Attempt attempt, List<QuizItem> items) async {
  try {
    if (attempt.subject != 'bangla' || !attempt.testId.startsWith('guide:')) {
      return null;
    }
    final setId = attempt.testId.substring('guide:'.length);
    if (setId.isEmpty || items.isEmpty) return null;
    final schoolClass = await resolveSchoolClass();
    final infos = await modelTestSetService.fetchSetsFromServer(
      'bangla',
      schoolClass: schoolClass,
    );
    if (infos == null) return null;
    final matches = infos.where((i) => i.setId == setId).toList();
    if (matches.isEmpty) return null;
    final bands = matches.first.gradeBands;
    if (bands == null || bands.isEmpty) return null;
    final rows = await modelTestSetService.fetchSetRows(
      'bangla',
      setId,
      schoolClass: schoolClass,
    );
    if (rows == null) return null;
    final marksById = <String, int>{};
    for (final r in rows) {
      if (r.marks != null) marksById[r.id] = r.marks!;
    }
    var total = 0;
    var max = 0;
    for (final q in items) {
      final m = marksById[q.id];
      if (m == null) return null;
      max += m;
      final a = attempt.answers[q.id];
      if (a != null && q.isCorrect(a)) total += m;
    }
    var bandMax = 0;
    for (final r in bands.values) {
      if (r.length == 2 && r[1] > bandMax) bandMax = r[1];
    }
    if (max != bandMax) return null;
    final letter = gradeForScore(bands, total);
    if (letter == null) return null;
    return RunGrade(letter, total, max);
  } catch (_) {
    return null;
  }
}
