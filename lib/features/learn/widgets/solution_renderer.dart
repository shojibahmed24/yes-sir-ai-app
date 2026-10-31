// Full-scroll card renderer for AI solutions. Default view:
// summary card + numbered steps + final-answer card; the toggle
// collapses back to summary-only. A summary identical to the
// final answer is skipped (final card still shows). Null
// solution + fallback text renders through the block renderer —
// never a blank screen, never raw markdown. The source toggle
// is setState only — never a new AI/Edge call. hideSummary
// (verbatim-first "steps" mode) hides the summary card so only
// steps + final show.
import 'package:flutter/material.dart';

import '../../../core/models/solution_model.dart';
import '../../../core/services/structured_parse.dart';
import '../../../theme/app_theme.dart';
import 'guide_math_text.dart';
import 'solution_blocks.dart';
import 'solution_source_chips.dart';
import 'solution_step_card.dart';

class SolutionRenderer extends StatefulWidget {
  const SolutionRenderer({
    super.key,
    required this.solution,
    required this.sourceChips,
    required this.fontSize,
    required this.s,
    required this.marksPrinted,
    this.fallbackText,
    this.questionText,
    this.questionLabel,
    this.explanationLabel,
    this.hideSummary = false,
  });
  final StructuredSolution? solution;
  final List<String> sourceChips;
  final double fontSize;
  final Map<String, String> s;
  final bool marksPrinted;
  final String? fallbackText;

  /// Verbatim question for the toggle; null = no toggle shown.
  final String? questionText;
  final String? questionLabel;
  final String? explanationLabel;

  /// Steps-only view: hide the summary card (steps + final).
  final bool hideSummary;

  @override
  State<SolutionRenderer> createState() => _SolutionRendererState();
}

class _SolutionRendererState extends State<SolutionRenderer> {
  bool _showFull = true;
  bool _showQuestion = false;

  // Theme-aware colours: onSurface is ink in light mode and a
  // light colour in dark mode (never forced AppTheme.ink, which
  // was unreadable on dark surfaces). The final-answer pair
  // follows the home hero-card pattern: light = heroTint +
  // heroTintOn, dark = primaryDark + white.
  Color get _onSurface => Theme.of(context).colorScheme.onSurface;
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _finalBg => _isDark ? AppTheme.primaryDark : AppTheme.heroTint;
  Color get _finalOn => _isDark ? Colors.white : AppTheme.heroTintOn;

  bool get _hasToggle =>
      widget.questionText != null &&
      widget.questionLabel != null &&
      widget.explanationLabel != null;

  Widget _questionView() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GuideMathText(
          text: widget.questionText!,
          fontSize: widget.fontSize,
          color: _onSurface,
        ),
      ),
    );
  }

  Widget _explanationView() {
    final solution = widget.solution;
    final s = widget.s;
    if (solution == null) {
      if (widget.fallbackText == null) return const SizedBox.shrink();
      return SolutionBlocks(
        text: widget.fallbackText!,
        fontSize: widget.fontSize,
      );
    }
    // Duplicate guard (same normalization as the service-side
    // retry guard): never show the same text twice as both
    // summary and final answer.
    final hideSummary = widget.hideSummary ||
        summaryEqualsFinal(solution.summary, solution.finalAnswer);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!hideSummary) Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s['solutionSummary']!,
                  style: TextStyle(
                    fontSize: widget.fontSize + 2,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'HindSiliguri',
                    color: _onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                SolutionBlocks(
                  text: solution.summary,
                  fontSize: widget.fontSize,
                ),
              ],
            ),
          ),
        ),
        if (!hideSummary) const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() => _showFull = !_showFull),
          child: Text(
            _showFull ? s['showSummaryOnly']! : s['showFullSolution']!,
          ),
        ),
        if (_showFull) ...[
          for (final step in solution.steps) ...[
            SolutionStepCard(
              step: step,
              fontSize: widget.fontSize,
              showMarks: widget.marksPrinted,
              marksWord: s['marksWord']!,
            ),
            const SizedBox(height: 12),
          ],
          if (solution.whyCorrect != null) ...[
            Text(
              s['whyCorrect']!,
              style: TextStyle(
                fontSize: widget.fontSize + 1,
                fontWeight: FontWeight.w600,
                fontFamily: 'HindSiliguri',
                color: _onSurface,
              ),
            ),
            const SizedBox(height: 4),
            SolutionBlocks(
              text: solution.whyCorrect!,
              fontSize: widget.fontSize,
            ),
            const SizedBox(height: 12),
          ],
          if (solution.whyOthersWrong != null) ...[
            Text(
              s['whyOthersWrong']!,
              style: TextStyle(
                fontSize: widget.fontSize + 1,
                fontWeight: FontWeight.w600,
                fontFamily: 'HindSiliguri',
                color: _onSurface,
              ),
            ),
            const SizedBox(height: 4),
            SolutionBlocks(
              text: solution.whyOthersWrong!,
              fontSize: widget.fontSize,
            ),
            const SizedBox(height: 12),
          ],
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _finalBg,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s['finalAnswer']!,
                style: TextStyle(
                  fontSize: widget.fontSize + 2,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'HindSiliguri',
                  color: _finalOn,
                ),
              ),
              const SizedBox(height: 8),
              SolutionBlocks(
                text: solution.finalAnswer,
                fontSize: widget.fontSize,
                color: _finalOn,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_hasToggle) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text(widget.explanationLabel!),
                selected: !_showQuestion,
                onSelected: (v) {
                  if (v) setState(() => _showQuestion = false);
                },
              ),
              ChoiceChip(
                label: Text(widget.questionLabel!),
                selected: _showQuestion,
                onSelected: (v) {
                  if (v) setState(() => _showQuestion = true);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        SolutionSourceChips(labels: widget.sourceChips),
        const SizedBox(height: 12),
        _showQuestion ? _questionView() : _explanationView(),
      ],
    );
  }
}
