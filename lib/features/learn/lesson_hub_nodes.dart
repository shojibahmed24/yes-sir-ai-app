// Lesson rows of the chapter picker: each opens the Phase-3 lesson
// hub (content types separated) instead of the old inline type step.
// Extracted so global_picker_tree.dart stays under the 250-line cap.
import 'global_picker_model.dart';
import 'lesson_hub_route.dart';
import 'lesson_order.dart';
import 'search_flow_lesson_counts.dart';

/// Row subtitle: the "extra set" marker for a compilation heading,
/// plus the type counts when they are known.
String? _subtitleFor(
  LessonEntry e,
  SearchFlowLessonCounts counts,
  int chapter,
  Map<String, String> s,
  bool bn,
) {
  final parts = <String>[
    if (e.compilation) s['extraSetLabel'] ?? '',
    lessonCountsLine(counts.of(chapter, e.value), s, bn) ?? '',
  ].where((p) => p.isNotEmpty).toList();
  return parts.isEmpty ? null : parts.join(' · ');
}

List<GlobalPickerNode> lessonHubNodes({
  required String subject,
  required int schoolClass,
  required int chapter,
  required Map<String, String> lessons,
  required SearchFlowLessonCounts counts,
  required Map<String, String> s,
  required bool bn,
}) {
  return [
    GlobalPickerNode(
      id: 'lesson:$chapter:all',
      title: s['lessonAll']!,
      subtitle: lessonCountsLine(counts.of(chapter, null), s, bn),
      kind: GlobalPickerNodeKind.lesson,
      hasChildren: false,
      pick: GlobalPickerPick.route(
        lessonHubRoute(
          subject: subject,
          schoolClass: schoolClass,
          chapter: chapter,
          lesson: null,
          title: s['lessonAll']!,
        ),
      ),
    ),
    for (final e in orderLessonEntries(lessons))
      GlobalPickerNode(
        id: 'lesson:$chapter:${e.value}',
        // B11: syllabus order (১.১ → ১.১.৪), compilation headings at
        // the end and marked as a set — never mixed into the lessons.
        title: e.title == e.value ? e.value : '${e.value} · ${e.title}',
        subtitle: _subtitleFor(e, counts, chapter, s, bn),
        kind: GlobalPickerNodeKind.lesson,
        hasChildren: false,
        pick: GlobalPickerPick.route(
          lessonHubRoute(
            subject: subject,
            schoolClass: schoolClass,
            chapter: chapter,
            lesson: e.value,
            title: e.title == e.value ? e.value : '${e.value} · ${e.title}',
          ),
        ),
      ),
  ];
}
