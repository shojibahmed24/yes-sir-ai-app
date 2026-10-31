// Structured-solution prompts, split out of
// structured_explanation_service.dart to keep it under the
// 250-line limit. Prompt wording only — no parsing, no policy.
import '../models/backend_models.dart';
import 'marks_budget.dart';

String structuredSystemPrompt(bool bangla, MarksBudget budget, bool strict) {
  final lang = bangla ? 'Bangla' : 'English';
  final strictNote = strict
      ? ' STRICT: follow the shape and the marks budget exactly.'
      : '';
  return 'You are a school teacher. Reply with JSON ONLY, no '
      'markdown fences, matching this shape: {"summary": "1-2 '
      'line PLAN of what will be done, operations in order", '
      '"steps": [{"n": 1, "title": "short heading", '
      '"text": "step body", "formulaLatex": "LaTeX or empty", '
      '"sectionLabel": "ক/খ/গ/ঘ or empty", "sectionMarks": 0}], '
      '"finalAnswer": "the answer with its unit, plus a one-line '
      'answer sentence", "correctOption": "MCQ only", '
      '"whyCorrect": "MCQ only", "whyOthersWrong": "MCQ only"}. '
      'The summary is a PLAN, never a restatement of the final '
      'answer: name the operations in order and any key '
      'conversion or assumption the solution needs (a unit '
      'change, a value assumed where the question leaves it '
      'open). Summary says WHAT will be done, finalAnswer says '
      'the RESULT — the two must differ. If units differ, '
      'convert them in an early step before computing; an '
      'assumption gets at most one step line, never the whole '
      'solution. '
      'Write in $lang. Formulas in LaTeX wrapped in \$...\$ '
      'delimiters so they render as typeset math, never caret-text. '
      'Never copy hidden grounding verbatim; rewrite its steps '
      'in your own words. Formulas, symbols and notation '
      'must be re-derived, never quoted from OCR text. '
      'Marks budget: '
      '${budget.guidance} At most ${budget.maxSteps} steps and '
      '${budget.maxLines} lines. Word counts are approximate; '
      'step count and shape are the real control.'
      '$strictNote';
}

/// Hard cap for one grounding block in a TRIMMED retry prompt
/// (2026-11-01 diagnosis: long Bengali prompts + long JSON output
/// never complete on the slow free model, so the retry prompt is
/// deliberately smaller on both input and output). Untrimmed
/// (first-attempt) prompts are untouched — trimming applies only
/// to the retry, never to the quality-first attempt.
String _cap(String s, int n) =>
    s.length <= n ? s : '${s.substring(0, n)}…';

String structuredUserPrompt(GroundedContext ctx, String style,
    String? followUp, {bool trimmed = false}) {
  final b = StringBuffer()
    ..writeln('Question (verbatim): ${ctx.questionText}');
  if (ctx.answerKey.isNotEmpty) {
    b.writeln('Verified correct answer (the screen shows this '
        'verbatim separately; explain WHY it is correct, and why '
        'the other options are wrong): ${ctx.answerKey}');
  }
  if (ctx.guideUnitText.isNotEmpty) {
    final unit = trimmed ? _cap(ctx.guideUnitText, 1200) : ctx.guideUnitText;
    b.writeln('HIDDEN worked solution for grounding ONLY — never '
        'quote it verbatim; rewrite its steps in your own words: '
        '$unit');
  }
  if (ctx.fallbackChunkText.isNotEmpty) {
    final note =
        trimmed ? _cap(ctx.fallbackChunkText, 600) : ctx.fallbackChunkText;
    b.writeln('Guide note (context only): $note');
  }
  // Trimmed retry: the first chapter chunk only, capped — the
  // retry must not re-send the full grounding that just timed out.
  final chunks = trimmed && ctx.chunkTexts.isNotEmpty
      ? [ctx.chunkTexts.first]
      : ctx.chunkTexts;
  for (var i = 0; i < chunks.length; i++) {
    final text = trimmed ? _cap(chunks[i], 800) : chunks[i];
    b.writeln('Book chapter text ${i + 1}: $text');
  }
  final follow = (followUp ?? '').trim();
  if (follow.isNotEmpty) b.writeln('Student follow-up: $follow');
  b.writeln('Style: $style. (short = tighter within the marks '
      'band; simple = simpler words; steps = numbered steps; '
      'examples = add one example step; beautiful = polished '
      'wording, same structure.)');
  return b.toString();
}
