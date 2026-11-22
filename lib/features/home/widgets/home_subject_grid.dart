// Home subject grid, split out to keep home_screen.dart under the
// 250-line file cap. Batch 2, item 3: subjects come from the same
// Supabase books source as Subjects/Books (booksService.
// subjectsAsync: subjects table + books_public + chapter counts when
// configured, DEMO fallback list otherwise) — ALL unlocked subjects,
// no mock list and no take(4) cut (ICT/BGS were cut before).
// The class is the PROFILE class (single source of truth, the same
// one Settings reads), never a hardcoded 6: the old grid always
// showed Class 6 subjects even when Settings said no class had
// been chosen yet. Null class shows an honest choose-class state
// instead of pretending Class 6.
//
// Cache-once grid: on mount it shows the PERSISTED last-good
// list instantly (no spinner, no server fetch). A fresh fetch
// happens only on first-ever load, on profile-class change, or
// on an explicit refresh (Subjects screen) — never on every
// mount, never periodically. A failed refresh keeps the old list
// silently and must never produce the empty state; the honest
// load-failed state (with retry) renders only when no saved list
// exists and the fetch fails. (Companion rules: only complete
// enrichments are persisted; DEMO fallbacks never are.)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/backend_models.dart';
import '../../../core/services/books_service.dart';
import '../../learn/learn_store.dart';
import '../../../l10n/pages/home_strings.dart';
import '../../../theme/staggered_list.dart';
import '../home_design.dart';
import 'home_subject_tile.dart';

/// Home-visible subjects: every unlocked subject, plus locked
/// subjects that have guide content. Locked subjects with neither
/// a book nor a guide stay hidden (honest empty, not a dead tile).
/// Guide sourcing (all classes): a subject whose textbook is locked
/// BUT which has guide-bank chapters (SubjectInfo.hasGuide, set by
/// subjectsAsync) is ALSO shown, and its tile goes to the new
/// search flow instead of the textbook chapters — so Class 9/10
/// Math is no longer an empty home.
///
/// [flagsComplete] false = some subject's guide state is UNKNOWN
/// (a probe failed). Hiding those made Home claim "no subjects
/// found", so unknown is never rendered as "no guide".
List<SubjectInfo> visibleHomeSubjects(
  List<SubjectInfo> all, {
  bool flagsComplete = true,
}) => flagsComplete ? all.where((x) => !x.locked || x.hasGuide).toList() : all;

/// Tile subtitle: guide-only subjects show their GUIDE count
/// (chapters, else model-test sets, else a generic guide note —
/// labelled as guide, never passed off as textbook chapters);
/// textbook subjects show their textbook count.
String _tileLabel(
  SubjectInfo s,
  bool bn,
  int? schoolClass,
  List<String> opened,
) {
  final done = schoolClass == null
      ? 0
      : LearnStore.openedChapterCount(opened, schoolClass, s.id);
  final pct = s.chapterCount > 0
      ? ((done / s.chapterCount) * 100).clamp(0, 100).round()
      : null;
  final suffix = pct == null ? '' : ' · $pct%';
  if (s.locked && s.hasGuide) {
    if (s.guideSetCount > 0) {
      final sets = bn
          ? homeStringsBn['guideSets']!
          : homeStringsEn['guideSets']!;
      final base = bn ? '${s.guideSetCount}$sets' : '${s.guideSetCount} $sets';
      return '$base$suffix';
    }
    if (s.guideChapterCount > 0) {
      final base = bn
          ? '${s.guideChapterCount}টি গাইড অধ্যায়'
          : '${s.guideChapterCount} guide chapters';
      return '$base$suffix';
    }
    return bn
        ? homeStringsBn['guideAvailable']!
        : homeStringsEn['guideAvailable']!;
  }
  final base = bn
      ? '${s.chapterCount}টি অধ্যায়'
      : '${s.chapterCount} chapters';
  return '$base$suffix';
}

/// True when two subject lists would render identical tiles.
bool _sameSubjects(List<SubjectInfo> a, List<SubjectInfo> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    final x = a[i], y = b[i];
    if (x.id != y.id ||
        x.nameBn != y.nameBn ||
        x.locked != y.locked ||
        x.hasGuide != y.hasGuide ||
        x.chapterCount != y.chapterCount ||
        x.guideChapterCount != y.guideChapterCount ||
        x.guideSetCount != y.guideSetCount) {
      return false;
    }
  }
  return true;
}

class HomeSubjectGrid extends StatefulWidget {
  const HomeSubjectGrid({
    super.key,
    required this.bn,
    required this.schoolClass,
    required this.loadingLabel,
    required this.noSubjectsLabel,
    required this.chooseClassTitle,
    required this.chooseClassBody,
    required this.chooseClassAction,
    this.opened = const [],
    this.service,
  });
  final bool bn;
  final int? schoolClass;
  final String loadingLabel;
  final String noSubjectsLabel;
  final String chooseClassTitle;
  final String chooseClassBody;
  final String chooseClassAction;

  /// Class-stamped opened chapter keys → per-subject % (D5).
  final List<String> opened;

  /// Overridable for tests; production uses the global service.
  final BooksService? service;

  @override
  State<HomeSubjectGrid> createState() => _HomeSubjectGridState();
}

class _HomeSubjectGridState extends State<HomeSubjectGrid> {
  List<SubjectInfo>? _subjects;
  bool _loadFailed = false;

  /// False when the last fetch could not resolve every subject's
  /// guide state (unknown ≠ no guide): locked tiles stay visible.
  bool _flagsComplete = true;

  /// First paint shows this many tiles (C4): the rest are appended on
  /// the next frame, so the grid appears immediately instead of
  /// building every card in one heavy pass.
  static const _firstPaintTiles = 6;
  int _shown = _firstPaintTiles;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(HomeSubjectGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.schoolClass != widget.schoolClass ||
        oldWidget.bn != widget.bn) {
      _subjects = null;
      _loadFailed = false;
      _load();
    }
  }

  Future<void> _load() async {
    final cls = widget.schoolClass;
    if (cls == null) return;
    final svc = widget.service ?? booksService;
    // Synchronous last-good list (B13): returning to Home paints the
    // grid on the first frame instead of "loading subjects".
    final sync = svc.lastGoodSync(cls, widget.bn);
    if (sync != null && sync.isNotEmpty && _subjects == null) {
      _subjects = sync;
    }
    // Cache-once: a saved list shows instantly and no server
    // fetch runs at all on this mount.
    final cached = await svc.loadPersistedSubjects(cls, widget.bn);
    if (!mounted) return;
    if (cached != null && cached.isNotEmpty) {
      setState(() {
        _subjects = cached;
        _loadFailed = false;
      });
      return;
    }
    // First-ever load (or a class with no saved list): fetch.
    // A failure keeps _subjects null so the honest load-failed
    // state renders — never the DEMO fallback disguised as
    // "no subjects".
    final result = await svc.fetchSubjectsFresh(cls, widget.bn);
    if (!mounted) return;
    if (result.kind == SubjectsFetchKind.failed) {
      if (_subjects == null) setState(() => _loadFailed = true);
      return;
    }
    if (_subjects == null || !_sameSubjects(_subjects!, result.subjects)) {
      setState(() {
        _subjects = result.subjects;
        _flagsComplete = result.complete;
        _loadFailed = false;
      });
    } else if (_flagsComplete != result.complete) {
      setState(() => _flagsComplete = result.complete);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cls = widget.schoolClass;
    if (cls == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.chooseClassTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(widget.chooseClassBody),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => context.go('/settings'),
            child: Text(widget.chooseClassAction),
          ),
        ],
      );
    }
    final subjects = _subjects;
    if (subjects == null) {
      // Load-failed state: no saved list AND the fetch failed.
      // This is a load failure, never "no subjects" — the server
      // never said the class has no subjects.
      if (_loadFailed) {
        final strings = widget.bn ? homeStringsBn : homeStringsEn;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings['subjectsLoadFailed']!),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _load,
              child: Text(strings['subjectsRetry']!),
            ),
          ],
        );
      }
      return Text(widget.loadingLabel);
    }
    final visible = visibleHomeSubjects(
      subjects,
      flagsComplete: _flagsComplete,
    );
    if (visible.isEmpty) return Text(widget.noSubjectsLabel);
    // C4: paint 6 tiles now, append the rest next frame.
    if (_shown < visible.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _shown < visible.length) {
          setState(() => _shown = visible.length);
        }
      });
    }
    final shown = visible.take(_shown).toList();
    // Batch 2, item 2: the old GridView fixed every tile height
    // via childAspectRatio 1.3, so a 2-3 line Bangla name at
    // headlineMedium pushed the chapter-count line outside the
    // card (Card clips nothing by default). Rows now size to
    // their tallest tile: IntrinsicHeight + stretch, the same
    // pattern that fixed the step-5 medium cards. Names wrap,
    // never truncate, and no text can paint outside a card.
    // UI palette (গ): grid rows stagger in (first 6 only).
    return StaggeredList(
      children: [
        for (var r = 0; r < shown.length; r += 2) ...[
          if (r > 0) const SizedBox(height: HomeDesign.cardGap),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: HomeSubjectTile(
                    name: paperSubjectName(
                      shown[r].id,
                      shown[r].name(widget.bn),
                      widget.bn,
                      widget.schoolClass,
                    ),
                    chaptersLabel: _tileLabel(
                      shown[r],
                      widget.bn,
                      widget.schoolClass,
                      widget.opened,
                    ),
                    subjectId: shown[r].id,
                    schoolClass: widget.schoolClass,
                  ),
                ),
                const SizedBox(width: HomeDesign.cardGap),
                if (r + 1 < shown.length)
                  Expanded(
                    child: HomeSubjectTile(
                      name: paperSubjectName(
                        shown[r + 1].id,
                        shown[r + 1].name(widget.bn),
                        widget.bn,
                        widget.schoolClass,
                      ),
                      chaptersLabel: _tileLabel(
                        shown[r + 1],
                        widget.bn,
                        widget.schoolClass,
                        widget.opened,
                      ),
                      subjectId: shown[r + 1].id,
                      schoolClass: widget.schoolClass,
                    ),
                  )
                else
                  const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
