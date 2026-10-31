// Per-part loading for the creative grouped view (step 6).
// Mirrors GuideAnswerScreen._load for ONE part id: resolveGuide
// (45s) gives stage-1 verbatim fields, then explainStructured
// (120s, the step-0 window: one GEN call capped at 55s, one
// trimmed retry) gives the explanation. Stage-1 is reported
// through onStage1 as soon as grounding arrives, so the view
// never hides a printed solution behind the slow AI call.
// Any failure yields a 'none' record with a null attempt —
// the body then shows the honest AI-first card + failed row
// with retry, never a fake solution.
import '../../../core/models/guide_bank_model.dart';
import '../../../core/services/explanation_service.dart';
import '../../../core/services/structured_explanation_service.dart';

/// One part's loaded state: stage-1 verbatim fields + the AI
/// explanation attempt (null = not run, or failed).
class CreativePartLoad {
  const CreativePartLoad({
    required this.verbatimKind,
    required this.verbatimText,
    required this.correctionNote,
    required this.guideError,
    this.attempt,
  });
  final String verbatimKind;
  final String verbatimText;
  final String correctionNote;
  final bool guideError;
  final StructuredAttempt? attempt;

  /// True when the server marked a printable guide answer.
  bool get hasVerbatim =>
      (verbatimKind == 'guide' || verbatimKind == 'corrected') &&
      verbatimText.isNotEmpty;
}

/// Called with the stage-1 record as soon as grounding lands.
typedef CreativePartStage1 = void Function(CreativePartLoad stage1);

/// Loads one part. The caller supplies subject/schoolClass via
/// the widget; tests inject a fake loader with this shape.
typedef CreativePartLoader = Future<CreativePartLoad> Function(
  GuideBankQuestion part,
  bool bn,
  CreativePartStage1 onStage1,
);

Future<CreativePartLoad> defaultCreativePartLoader({
  required GuideBankQuestion part,
  required String subjectId,
  required int schoolClass,
  required bool bn,
  required CreativePartStage1 onStage1,
}) async {
  const none = CreativePartLoad(
    verbatimKind: 'none',
    verbatimText: '',
    correctionNote: '',
    guideError: false,
  );
  Grounding? grounding;
  try {
    grounding = await structuredExplanationService
        .resolveGuide(
          guideQuestionId: part.id,
          subject: subjectId,
          schoolClass: schoolClass,
          bangla: bn,
        )
        .timeout(const Duration(seconds: 45));
  } catch (_) {
    return none;
  }
  if (!grounding.found || grounding.context == null) return none;
  final ctx = grounding.context!;
  final stage1 = CreativePartLoad(
    verbatimKind: ctx.verbatimKind,
    verbatimText: ctx.verbatimText,
    correctionNote: ctx.correctionNote,
    guideError: ctx.guideError,
  );
  onStage1(stage1);
  // Explanation failure must NOT discard stage-1: the body
  // shows the printed answer plus a failed row with retry.
  StructuredAttempt? attempt;
  try {
    attempt = await structuredExplanationService
        .explainStructured(grounding: grounding, style: 'steps', bangla: bn)
        .timeout(const Duration(seconds: 120));
  } catch (_) {
    attempt = null;
  }
  return CreativePartLoad(
    verbatimKind: stage1.verbatimKind,
    verbatimText: stage1.verbatimText,
    correctionNote: stage1.correctionNote,
    guideError: stage1.guideError,
    attempt: attempt,
  );
}
