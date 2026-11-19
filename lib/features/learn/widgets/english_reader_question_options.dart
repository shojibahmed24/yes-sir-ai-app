// Options + printed-answer block of one English reader
// question, split out of english_reader_question_card.dart
// (M5, 2026-11-08) to keep that file under the 250-line rule.
// Display only: grounding/explanation state still lives in
// the card; this widget renders what it is given.
import 'package:flutter/material.dart';

import '../../../core/models/guide_bank_model.dart';

const _optionLetters = ['ক', 'খ', 'গ', 'ঘ', 'ঙ'];

class EnglishReaderQuestionContent extends StatelessWidget {
  const EnglishReaderQuestionContent({
    super.key,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.isMcq,
    required this.groundingLoading,
    required this.verbatim,
    required this.verbatimText,
    required this.es,
    required this.textBuilder,
  });
  final GuideBankQuestion question;
  final List<String> options;
  final int? correctIndex;
  final bool isMcq;
  final bool groundingLoading;
  final bool verbatim;
  final String verbatimText;

  /// English search-flow strings (marks suffix, printed
  /// answer labels, unavailable note).
  final Map<String, String> es;

  /// Question/option/answer text renderer: plain Text when no
  /// translation service was injected, translated-field widget
  /// otherwise (owned by the card).
  final Widget Function(String value, TextStyle? style) textBuilder;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final q = question;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (q.marks != null)
          Text('${q.marks} ${es['marksSuffix']!}',
              style: text.bodySmall),
        if (options.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (var i = 0; i < options.length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: correctIndex == i
                      ? cs.primaryContainer
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      '${i < _optionLetters.length ? _optionLetters[i] : '${i + 1}'}. ',
                      style: text.bodyMedium?.copyWith(
                          fontFamily: 'HindSiliguri')),
                  Expanded(
                    child: textBuilder(options[i],
                        text.bodyMedium?.copyWith(
                            fontFamily: 'HindSiliguri')),
                  ),
                  if (correctIndex == i)
                    const Icon(Icons.check, size: 20),
                ],
              ),
            ),
        ],
        if (!isMcq) ...[
          const SizedBox(height: 12),
          if (groundingLoading)
            const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
          else if (verbatim)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(es['readerPrintedAnswer']!,
                      style: text.labelMedium?.copyWith(
                          fontFamily: 'HindSiliguri')),
                  const SizedBox(height: 4),
                  textBuilder(verbatimText,
                      text.bodyMedium?.copyWith(
                          fontFamily: 'HindSiliguri')),
                ],
              ),
            )
          else
            Text(es['readerAnswerUnavailable']!),
        ],
      ],
    );
  }
}
