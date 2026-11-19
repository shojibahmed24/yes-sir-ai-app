// Lesson rows of the chapter picker: each opens the Phase-3 lesson
// hub (content types separated) instead of the old inline type step.
// Extracted so global_picker_tree.dart stays under the 250-line cap.
import 'global_picker_model.dart';
import 'lesson_hub_route.dart';
import 'search_flow_lesson_counts.dart';

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
    for (final e in lessons.entries)
      GlobalPickerNode(
        id: 'lesson:$chapter:${e.key}',
        title: e.key == e.value ? e.key : '${e.key} · ${e.value}',
        subtitle: lessonCountsLine(counts.of(chapter, e.key), s, bn),
        kind: GlobalPickerNodeKind.lesson,
        hasChildren: false,
        pick: GlobalPickerPick.route(
          lessonHubRoute(
            subject: subject,
            schoolClass: schoolClass,
            chapter: chapter,
            lesson: e.key,
            title: e.key == e.value ? e.key : '${e.key} · ${e.value}',
          ),
        ),
      ),
  ];
}
