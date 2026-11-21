// List-route query string + subject lookup for the search
// flow controller, split out so the controller stays under
// the 250-line cap. The screen imports this file for
// listQuery(); the controller imports it for subject.
import '../../core/models/backend_models.dart';
import 'search_flow_controller.dart';

extension SearchFlowListQuery on SearchFlowController {
  SubjectInfo? get subject {
    for (final s in subjects) {
      if (s.id == subjectId) return s;
    }
    return null;
  }

  /// Query string for the list route (no navigation here).
  /// Section / set / Paper-II-section / chapterless modes omit
  /// `type` (a stale type pick must never leak in — the type->
  /// section mapping is Math's and would return wrong lists).
  /// `type` is null-guarded and the lesson is URI-encoded.
  String listQuery({
    int? questionNumber,
    String? setId,
    String? paper2Section,
    bool chapterless = false,
  }) {
    final q = <String, String>{
      'subject': effectiveSubjectId,
      'class': '$effectiveClass',
      'source': source,
      'chapter': '${chapter ?? 0}',
      if (englishGuideSectionMode && section != null) 'section': section!,
      if (paper2Section != null) 'section': paper2Section,
      if (setId != null) 'setId': setId,
      if (chapterless) 'chapterless': 'true',
      if (type != null &&
          paper2Section == null &&
          setId == null &&
          !chapterless)
        'type': type!.name,
      if (lesson != null) 'lesson': Uri.encodeComponent(lesson!),
      if (questionNumber != null) 'questionNumber': '$questionNumber',
    };
    return q.entries.map((e) => '${e.key}=${e.value}').join('&');
  }
}

/// Whether the type pick is still required before the list can be
/// shown. Sets / Bangla papers never ask for a type; Paper-II asks
/// for a section instead; everything else needs a type.
bool searchFlowNeedsType({
  required bool setMode,
  required bool banglaFirst,
  required bool banglaSecond,
  required bool paper2Mode,
  required bool paper2SectionPicked,
  required bool typePicked,
}) {
  if (setMode || banglaFirst || banglaSecond) return false;
  return paper2Mode ? !paper2SectionPicked : !typePicked;
}

/// The one hint line under the actions bar; null = ready to submit.
String? searchFlowActionHint({
  required bool setMode,
  required bool banglaFirst,
  required bool banglaSecond,
  required bool paper2Mode,
  required bool paper2SectionPicked,
  required bool chapterPicked,
  required bool needType,
  required Map<String, String> s,
}) {
  if (setMode || banglaFirst || banglaSecond) return null;
  if (paper2Mode) {
    return paper2SectionPicked ? null : s['actionHintSection'];
  }
  if (!chapterPicked && needType) return s['actionHintBoth'];
  if (!chapterPicked) return s['actionHintChapter'];
  return needType ? s['actionHintType'] : null;
}
