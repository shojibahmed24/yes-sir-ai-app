// Extracted from quiz_question_screen.dart (audit-fix Worker C,
// split-before-touch: that file was at the 250-line cap).
// The explanation card body for one checked quiz question.
// Live / DEMO / DEMO-bank explanation text renders through the
// shared SolutionBlocks renderer, never as raw Text, so AI
// markdown (**bold**, | tables |) never reaches the screen
// raw. Code fences are stripped first: SolutionBlocks consumes
// ** and | but not ``` fence lines, so a fenced AI reply
// would otherwise still show its fences.
import 'package:flutter/material.dart';
import 'package:yes_sir_ai/features/learn/widgets/solution_blocks.dart';

/// Drops lines that are ``` code fences (``` or ```lang).
/// Inline content is untouched; only whole fence lines go.
String stripCodeFences(String text) => text
    .split('\n')
    .where((line) => !line.trim().startsWith('```'))
    .join('\n');

class QuizExplanationBody extends StatelessWidget {
  const QuizExplanationBody({
    super.key,
    required this.loading,
    required this.kind,
    required this.text,
    required this.s,
  });

  /// True while this question's explanation is being fetched.
  final bool loading;

  /// 'live' | 'demo' | 'demo-bank' | 'missing' |
  /// 'serverKeyMissing' | null (not fetched yet).
  final String? kind;

  /// The explanation text, when fetched (live / demo / demo-bank).
  final String? text;

  /// Quiz-question page strings (bn or en map).
  final Map<String, String> s;

  @override
  Widget build(BuildContext context) {
    if (loading) return Text(s['aiLoading']!);
    if (kind == 'missing') {
      return Text('${s['tipTitle']!}: ${s['notIndexed']!} ${s['askExact']!}');
    }
    if (kind == 'serverKeyMissing') {
      return Text(s['aiServerKeyMissing']!);
    }
    if (text == null || kind == null) return Text(s['aiLoading']!);
    final label = kind == 'live'
        ? s['aiLive']!
        : kind == 'demo-bank'
            ? s['aiDemoBank']!
            : s['aiDemo']!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        SolutionBlocks(text: stripCodeFences(text!), fontSize: 16),
      ],
    );
  }
}
