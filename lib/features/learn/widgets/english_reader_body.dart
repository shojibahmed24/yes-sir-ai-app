// English reader body sections, split out of
// english_reader_screen.dart (D1/M5, 2026-11-08) to keep that
// file under the 250-line rule. The screen keeps state, loading
// and navigation; this file owns only the passage box, the
// scrolling question area, and the pure label helpers the
// screen used to carry inline.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/data/english_reader_shape.dart';
import '../../../core/data/english_redesign.dart';
import '../../../core/models/guide_bank_model.dart';
import '../../../core/services/english_reader_service.dart';
import '../../../core/services/english_translation_service.dart';
import 'english_reader_end_card.dart';
import 'english_reader_jump_bar.dart';
import 'english_reader_passage_box.dart';
import 'english_reader_question_card.dart';
import 'english_reader_question_nav.dart';

/// Passage parts for the CURRENT question: its own stimulus
/// text when it carries one, else the test's dominant parts.
/// A multi-passage test therefore shows each question's own
/// passage instead of one passage for every question.
List<String> englishReaderCurrentParts(
    EnglishReaderData? data, int groupIndex, int questionIndex) {
  if (data == null || data.groups.isEmpty) return const [];
  final q = data.groups[groupIndex].questions[questionIndex];
  final t = q.stimulusText;
  if (t != null && t.trim().isNotEmpty) {
    return splitPassageParts(t);
  }
  return data.parts;
}

/// Chip labels: Q-numbers for tests, section labels for
/// practice, set labels for poems/stories; empty while loading.
List<String> englishReaderChipLabels(EnglishReaderData? data,
    EnglishReaderKind kind, bool bn, Map<String, String> fs) {
  if (data == null) return const [];
  return [
    for (final g in data.groups)
      if (kind == EnglishReaderKind.model ||
          kind == EnglishReaderKind.special)
        englishTestQuestionLabel(g.section ?? '') ?? g.section ?? ''
      else if (kind == EnglishReaderKind.poem ||
          kind == EnglishReaderKind.story)
        setDisplayLabel(g.setId, bn)
      else
        fs[englishRedesignSectionStringKey(g.section ?? '')] ??
            g.section ?? ''
  ];
}

/// "Q3 · ২" style header for the current question.
String englishReaderHeader(
    List<String> labels, int groupIndex, int questionIndex, bool bn) {
  final sub =
      bn ? bnDigits(questionIndex + 1) : '${questionIndex + 1}';
  return '${labels[groupIndex]} · $sub';
}

/// The sticky passage box. D1 (2026-11-08): its height used to
/// be a fixed 280dp, which ate 44% of a 640dp portrait screen
/// and left ~48dp for the question in landscape. It is now a
/// fraction of the screen height, capped at 280dp.
class EnglishReaderPassageSection extends StatelessWidget {
  const EnglishReaderPassageSection({
    super.key,
    required this.title,
    required this.parts,
    required this.partIndex,
    required this.bn,
    required this.es,
    required this.translate,
    required this.translationService,
    required this.onPrevPart,
    required this.onNextPart,
  });
  final String title;
  final List<String> parts;
  final int partIndex;
  final bool bn;
  final Map<String, String> es;
  final bool translate;
  final EnglishTranslationService translationService;
  final VoidCallback onPrevPart;
  final VoidCallback onNextPart;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return SizedBox(
      height: math.min(280, height * 0.38),
      child: EnglishReaderPassageBox(
        title: title,
        parts: parts,
        partIndex: partIndex,
        bn: bn,
        s: es,
        onPrevPart: onPrevPart,
        onNextPart: onNextPart,
        translate: translate,
        translationService: translationService,
        failedNote: es['readerTranslateFailed']!,
        retryLabel: es['readerTranslateRetry']!,
      ),
    );
  }
}

/// The scrolling question area below the passage box: end card
/// after the last question, else one question card, then the
/// prev/next nav and the jump bar at the END of the scrolled
/// page (never fixed over content).
class EnglishReaderQuestionSection extends StatelessWidget {
  const EnglishReaderQuestionSection({
    super.key,
    required this.showEnd,
    required this.seenCount,
    required this.groupCount,
    required this.onBack,
    required this.header,
    required this.question,
    required this.schoolClass,
    required this.bn,
    required this.es,
    required this.gs,
    required this.ls,
    required this.translate,
    required this.translationService,
    required this.canPrev,
    required this.onPrevQuestion,
    required this.onNextQuestion,
    required this.labels,
    required this.groupIndex,
    required this.seen,
    required this.onJump,
  });
  final bool showEnd;
  final int seenCount;
  final int groupCount;
  final VoidCallback onBack;
  final String header;
  final GuideBankQuestion question;
  final int schoolClass;
  final bool bn;
  final Map<String, String> es;
  final Map<String, String> gs;
  final Map<String, String> ls;
  final bool translate;
  final EnglishTranslationService translationService;
  final bool canPrev;
  final VoidCallback onPrevQuestion;
  final VoidCallback onNextQuestion;
  final List<String> labels;
  final int groupIndex;
  final Set<int> seen;
  final void Function(int groupIndex) onJump;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: [
            if (showEnd)
              EnglishReaderEndCard(
                  seenCount: seenCount,
                  groupCount: groupCount,
                  s: es,
                  onBack: onBack)
            else
              EnglishReaderQuestionCard(
                header: header,
                question: question,
                schoolClass: schoolClass,
                bn: bn,
                es: es,
                gs: gs,
                ls: ls,
                translate: translate,
                translationService: translationService,
              ),
            if (!showEnd)
              EnglishReaderQuestionNav(
                canPrev: canPrev,
                s: es,
                onPrev: onPrevQuestion,
                onNext: onNextQuestion,
              ),
            EnglishReaderJumpBar(
              labels: labels,
              current: groupIndex,
              seen: seen,
              onJump: onJump,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// The reader AppBar: back + ellipsised title (R2) + the
/// Bangla-translation switch. Kept here so the screen file
/// stays under the 250-line rule.
AppBar englishReaderAppBar({
  required String title,
  required bool translate,
  required Map<String, String> es,
  required VoidCallback onBack,
  required ValueChanged<bool> onToggleTranslate,
}) {
  return AppBar(
    leading: IconButton(
        icon: const Icon(Icons.arrow_back), onPressed: onBack),
    // R2: long set/lesson names must ellipsize instead of
    // overflowing past the translate switch.
    title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
    actions: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(es['readerTranslate']!),
          Switch(value: translate, onChanged: onToggleTranslate),
        ],
      ),
    ],
  );
}
