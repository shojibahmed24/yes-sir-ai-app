// Chat grounding dispatch, split out of chat_screen.dart to keep
// that file under the 250-line cap. Guide selections (opened
// from a guide answer) resolve via Mode G (resolveGuide, the
// same path the step-by-step explanation already uses) and
// NEVER touch the textbook index — page/problem 0 is not a
// lesson lookup. Textbook selections keep the exact old dispatch
// (by-id, else page/problem resolve).
import '../../core/services/explanation_service.dart';
import '../../core/services/structured_explanation_service.dart';
import 'lesson_grounding.dart';
import 'lesson_selection.dart';

/// Resolved grounding plus whether it came from a guide row.
class ChatGrounding {
  const ChatGrounding(this.grounding, this.isGuide);
  final Grounding grounding;
  final bool isGuide;
}

Future<ChatGrounding> resolveChatGrounding(
  LessonSelection sel,
  int schoolClass,
  bool bn,
) async {
  final guideId = sel.guideQuestionId;
  if (guideId != null) {
    final grounding = await structuredExplanationService.resolveGuide(
      guideQuestionId: guideId,
      subject: sel.subject,
      schoolClass: schoolClass,
      bangla: bn,
    );
    return ChatGrounding(grounding, true);
  }
  if (sel.questionId != null) {
    return ChatGrounding(await resolveLessonGrounding(sel, bn), false);
  }
  return ChatGrounding(
    await explanationService.resolve(
      subject: sel.subject,
      schoolClass: schoolClass,
      chapter: sel.chapter,
      page: sel.page,
      problem: sel.problem,
      bangla: bn,
    ),
    false,
  );
}
