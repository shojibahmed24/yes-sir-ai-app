// Verbatim question + AI explanation for one book-lookup result.
// The question text is shown FIRST, exactly as the Edge Function
// returned it — the AI text below is only an explanation of it.
// The DEMO / live label is explicit: DEMO means no OpenRouter key
// at build time (see explanation_service.explain), live means the
// OpenRouter call succeeded. Ungrounded input never reaches here.
import 'package:flutter/material.dart';
import '../../../core/services/explanation_service.dart';
import 'solution_blocks.dart';

class BookLookupDetail extends StatefulWidget {
  const BookLookupDetail({
    super.key,
    required this.grounding,
    required this.bn,
    required this.s,
  });
  final Grounding grounding;
  final bool bn;
  final Map<String, String> s;
  @override
  State<BookLookupDetail> createState() => _BookLookupDetailState();
}

class _BookLookupDetailState extends State<BookLookupDetail> {
  ExplanationResult? _result;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _run();
  }

  /// A failed call must end the "loading explanation" state with the
  /// honest failed row, never spin forever (the old .then() had no
  /// onError).
  Future<void> _run() async {
    try {
      final r = await explanationService.explain(
        grounding: widget.grounding,
        style: 'simple',
        bangla: widget.bn,
      );
      if (mounted) {
        setState(() {
          _result = r;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _result = null;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctx = widget.grounding.context!;
    final s = widget.s;
    final chip =
        '${s['chapterLabel']!} ${ctx.chapterNumber} · '
        '${s['pageShort']!} ${ctx.page} · '
        '${ctx.problem > 0 ? '${s['questionShort']!} ${ctx.problem}' : s['unnumbered']!}';
    final result = _result;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        Chip(label: Text(chip)),
        const SizedBox(height: 8),
        Text(
          s['verbatimLabel']!,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(ctx.questionText, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 16),
        if (_loading && result == null)
          Text(s['explainLoading']!)
        else if (result == null || result.outcome == ExplanationOutcome.failed)
          Text(s['explainFailed']!)
        else ...[
          Chip(
            label: Text(
              result.outcome == ExplanationOutcome.demo
                  ? s['demoLabel']!
                  : s['liveLabel']!,
            ),
          ),
          const SizedBox(height: 8),
          // Audit-fix B1: AI explanation via shared SolutionBlocks,
          // never raw Text. Fence lines are stripped first because
          // SolutionBlocks consumes ** and | but not ``` fences.
          // The verbatim question above stays plain Text on purpose.
          SolutionBlocks(
            text: result.text
                .split('\n')
                .where((line) => !line.trim().startsWith('```'))
                .join('\n'),
            fontSize: 16,
          ),
        ],
      ],
    );
  }
}
