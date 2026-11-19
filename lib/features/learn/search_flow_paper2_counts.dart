// Paper-II (english-2nd) section reality for the global picker.
// The 15 section values are the exam order (a static list), but the
// paper is NOT fully in the live guide: on 2026-11-20 the live
// english-2nd subject held the four writing sections only, and the
// eleven grammar sections returned total 0. Offering an empty
// branch is dishonest UI, so each section's exact total is read
// with one tiny chapterless list call (limit 1, slim).
//
// Rules:
// - A section whose total is 0 is hidden: zero is a server fact.
// - A section whose count is unknown (older server without the
//   section echo, network error, or not asked yet) stays VISIBLE.
//   A branch is never hidden on a guess.
// - A total is never estimated; only the echoed server total counts.
import 'dart:ui' show VoidCallback;

import '../../core/data/paper2_sections.dart';
import '../../core/services/guide_flow_count_service.dart';

class Paper2SectionCounts {
  Paper2SectionCounts({required this.onChanged, GuideFlowCountService? service})
    : _svc = service ?? guideFlowCountService;

  final VoidCallback onChanged;
  final GuideFlowCountService _svc;

  /// section -> exact total, or null when that one is unknown.
  /// Empty map = nothing known yet: every section stays visible.
  Map<String, int?> counts = const {};
  bool loading = false;
  int _generation = 0;

  /// Loads every section's total in parallel, once per call.
  /// Superseded runs (subject/class changed) are dropped whole.
  Future<void> load({required int schoolClass}) async {
    final gen = ++_generation;
    loading = true;
    onChanged();
    final out = <String, int?>{};
    await Future.wait([
      for (final section in paperTwoSections)
        () async {
          out[section] = await _svc.countPaperTwoSection(
            subject: 'english-2nd',
            schoolClass: schoolClass,
            section: section,
          );
        }(),
    ]);
    if (gen != _generation) return;
    loading = false;
    counts = out;
    onChanged();
  }

  /// Leaving the subject: drop every count (no stale section list).
  void clear() {
    _generation++;
    counts = const {};
    loading = false;
    onChanged();
  }
}
