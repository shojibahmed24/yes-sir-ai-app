// Structured AI solution model — the output contract for the
// answer screen (locked 2026-10-29). The AI returns JSON, never a
// wall of text: summary, numbered steps, final answer. MCQ adds
// the correct option + why; creative adds marks-split sections.
// Formulas arrive as LaTeX (formulaLatex), never caret-text.
// Tables arrive as data (headers + rows), never comma-paragraphs.
// Parsing is strict: any missing/wrong-typed required field makes
// the whole payload invalid (caller falls back to plain markdown).
// No guide or textbook text lives here — only the shape.

/// One comparison table inside a step.
class SolutionTable {
  final List<String> headers;
  final List<List<String>> rows;
  const SolutionTable({required this.headers, required this.rows});
}

/// One numbered step of a solution.
class SolutionStep {
  final int n;
  final String title;
  final String text;

  /// LaTeX formula for this step, if any (e.g. r'\frac{60}{40}').
  final String? formulaLatex;
  final SolutionTable? table;

  /// Creative sub-part label ('ক' | 'খ' | 'গ' | 'ঘ'), if any.
  final String? sectionLabel;

  /// Printed marks of this section, if any. Null = unprinted:
  /// the UI must show NO marks badge for it, never an invented one.
  final int? sectionMarks;
  const SolutionStep({
    required this.n,
    required this.title,
    required this.text,
    this.formulaLatex,
    this.table,
    this.sectionLabel,
    this.sectionMarks,
  });
}

/// A full structured solution, ready for the card renderer.
class StructuredSolution {
  final String summary;
  final List<SolutionStep> steps;
  final String finalAnswer;

  /// MCQ only: the option the AI claims is correct.
  final String? correctOption;
  final String? whyCorrect;
  final String? whyOthersWrong;
  const StructuredSolution({
    required this.summary,
    required this.steps,
    required this.finalAnswer,
    this.correctOption,
    this.whyCorrect,
    this.whyOthersWrong,
  });
}

String _asString(dynamic v) => v is String ? v : '';
int? _asInt(dynamic v) => v is num ? v.toInt() : null;

SolutionTable? _parseTable(dynamic v) {
  if (v is! Map) return null;
  final headers = (v['headers'] as List?)
      ?.whereType<String>()
      .where((s) => s.isNotEmpty)
      .toList();
  final rows = (v['rows'] as List?)
      ?.whereType<List>()
      .map((r) => r.whereType<String>().toList())
      .where((r) => r.isNotEmpty)
      .toList();
  if (headers == null || headers.isEmpty || rows == null || rows.isEmpty) {
    return null;
  }
  return SolutionTable(headers: headers, rows: rows);
}

/// Strict parse: returns null unless the payload matches the
/// contract exactly (required fields present and correctly typed).
StructuredSolution? parseStructuredSolution(dynamic data) {
  if (data is! Map) return null;
  final summary = _asString(data['summary']);
  final finalAnswer = _asString(data['finalAnswer']);
  final rawSteps = data['steps'];
  if (summary.isEmpty || finalAnswer.isEmpty || rawSteps is! List) {
    return null;
  }
  final steps = <SolutionStep>[];
  for (final raw in rawSteps) {
    if (raw is! Map) return null;
    final n = _asInt(raw['n']);
    final text = _asString(raw['text']);
    if (n == null || text.isEmpty) return null;
    final formula = _asString(raw['formulaLatex']);
    steps.add(SolutionStep(
      n: n,
      title: _asString(raw['title']),
      text: text,
      formulaLatex: formula.isEmpty ? null : formula,
      table: _parseTable(raw['table']),
      sectionLabel: _asString(raw['sectionLabel']).isEmpty
          ? null
          : _asString(raw['sectionLabel']),
      sectionMarks: _asInt(raw['sectionMarks']),
    ));
  }
  if (steps.isEmpty) return null;
  final correctOption = _asString(data['correctOption']);
  final whyCorrect = _asString(data['whyCorrect']);
  final whyOthersWrong = _asString(data['whyOthersWrong']);
  return StructuredSolution(
    summary: summary,
    steps: steps,
    finalAnswer: finalAnswer,
    correctOption: correctOption.isEmpty ? null : correctOption,
    whyCorrect: whyCorrect.isEmpty ? null : whyCorrect,
    whyOthersWrong: whyOthersWrong.isEmpty ? null : whyOthersWrong,
  );
}

/// Key-check gate (locked verbatim policy): the AI draft's claimed
/// correct option must equal the stored printed key. Comparison is
/// whitespace/case-insensitive; anything else is a mismatch and
/// the caller must discard the draft and show the key instead.
bool solutionMatchesKey(StructuredSolution solution, String storedKey) {
  final claimed = solution.correctOption;
  if (claimed == null) return false;
  return claimed.trim().toLowerCase() ==
      storedKey.trim().toLowerCase();
}
