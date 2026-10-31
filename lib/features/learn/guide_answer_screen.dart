// Route: /guide-answer — answer for one guide bank question
// (via GuideAnswerHolder). Mode G resolveGuide grounding;
// honestly reports unavailable, never demo data as real.
// Verbatim-first: the guide's own answer shows first when the
// server marks it verbatim, else the AI explanation directly
// (or behind detail/steps buttons when verbatim exists).
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/guide_bank_model.dart';
import '../../core/services/guide_quiz_service.dart';
import '../../core/services/structured_explanation_service.dart';
import '../../l10n/language_provider.dart';
import '../../l10n/pages/guide_bank_strings.dart';
import '../../l10n/pages/lesson_strings.dart';
import 'guide_answer_holder.dart';
import 'lesson_selection.dart';
import 'widgets/guide_answer_body.dart';
import 'widgets/guide_creative_answer_view.dart';
import 'widgets/guide_message_state.dart';

class GuideAnswerScreen extends StatefulWidget {
  const GuideAnswerScreen({super.key});

  @override
  State<GuideAnswerScreen> createState() => _GuideAnswerScreenState();
}

class _GuideAnswerScreenState extends State<GuideAnswerScreen> {
  bool _loading = true;
  bool _unavailable = false;
  StructuredAttempt? _attempt;
  // Pilot (2026-10-31): the AI explanation runs AFTER stage-1
  // is already on screen. _explaining covers the window between
  // grounding arrival and the explanation result, so the body
  // shows a pending row instead of a premature failed row.
  bool _explaining = false;
  double _fontSize = 16;
  String _verbatimKind = 'none';
  String _verbatimText = '';
  String _answerKeyLetter = '';
  String _correctionNote = '';
  bool _guideError = false;
  bool _showExplanation = true;
  bool _stepsOnly = false;

  @override
  void initState() {
    super.initState();
    // Group mode loads its own parts; skip the duplicate single _load.
    if (GuideAnswerHolder.group == null) _load();
  }

  Future<void> _load() async {
    final q = GuideAnswerHolder.question;
    if (q == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _unavailable = true;
        });
      }
      return;
    }
    final bn = languageNotifier.value.languageCode == 'bn';
    // resolveGuide 45s; explanation 120s (2026-11-01: one GEN
    // call caps at 55s + one trimmed retry). Stage-1 renders
    // first, so the long window never blocks the guide answer.
    // Failures -> honest failed state + retry; found=false ->
    // unavailable; demo data is never shown as real.
    try {
      final grounding = await structuredExplanationService
          .resolveGuide(
            guideQuestionId: q.id,
            subject: GuideAnswerHolder.subjectId,
            schoolClass: GuideAnswerHolder.schoolClass,
            bangla: bn,
          )
          .timeout(const Duration(seconds: 45));
      if (!mounted) return;
      if (!grounding.found) {
        setState(() {
          _loading = false;
          _unavailable = true;
        });
        return;
      }
      final ctx = grounding.context;
      if (ctx != null) {
        _verbatimKind = ctx.verbatimKind;
        _verbatimText = ctx.verbatimText;
        _answerKeyLetter = ctx.answerKey;
        _correctionNote = ctx.correctionNote;
        _guideError = ctx.guideError;
        _showExplanation = !ctx.hasVerbatim;
      }
      // STAGE-1 FIRST: the guide's own solution renders as soon
      // as grounding arrives; the explanation fills in below.
      if (mounted) {
        setState(() {
          _loading = false;
          _explaining = true;
        });
      }
      final attempt = await structuredExplanationService
          .explainStructured(grounding: grounding, style: 'steps', bangla: bn)
          .timeout(const Duration(seconds: 120));
      if (!mounted) return;
      setState(() {
        _explaining = false;
        _attempt = attempt;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _explaining = false;
        _attempt = null;
      });
    }
  }

  // Ask-AI: opens /lesson/chat grounded in this exact guide
  // row (Mode G via guideQuestionId, never textbook page 0).
  // Back returns here: returnTo is the guide answer route.
  void _openChat(GuideBankQuestion q) {
    LessonSelectionHolder.set(LessonSelection(
      subject: GuideAnswerHolder.subjectId, chapter: GuideAnswerHolder.chapterNumber,
      page: 0, problem: 0, queryText: q.questionText,
      schoolClass: GuideAnswerHolder.schoolClass,
      guideQuestionId: q.id, returnTo: '/guide-answer'));
    context.go('/lesson/chat');
  }

  /// Grouped view, or null for the single-question body.
  Widget? _groupBody(bool bn, Map<String, String> s, Map<String, String> ls) {
    final group = GuideAnswerHolder.group;
    if (group == null || group.isEmpty) return null;
    return GuideCreativeAnswerView(
      parts: group, stimulusText: GuideAnswerHolder.stimulusText,
      subjectId: GuideAnswerHolder.subjectId,
      chapterNumber: GuideAnswerHolder.chapterNumber,
      schoolClass: GuideAnswerHolder.schoolClass,
      bn: bn, s: s, ls: ls, onAskAi: _openChat,
    );
  }

  /// Back returns to the new-flow list that opened this answer
  /// (holder.returnTo), never the deleted /guide-bank route.
  void _back() => context.go(GuideAnswerHolder.returnTo);

  String? _keyText(GuideBankQuestion q) {
    if (q.hasKey) return q.options[q.correctOptionIndex!];
    if (q.answerKeyText.isNotEmpty) return q.answerKeyText;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final bn = locale.languageCode == 'bn';
        final s = bn ? guideBankStringsBn : guideBankStringsEn;
        final ls = bn ? lessonStringsBn : lessonStringsEn;
        final q = GuideAnswerHolder.question;
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _back,
            ),
            title: Text(s['title']!),
          ),
          body: _groupBody(bn, s, ls) ??
              (_loading
              ? Center(child: Text(s['loading']!))
              : (_unavailable || q == null)
              ? GuideMessageState(
                  title: s['answerUnavailable']!,
                  buttonLabel: s['back']!,
                  onPressed: _back,
                )
              : _body(q, bn, s, ls)),
        );
      },
    );
  }

  Widget _body(
    GuideBankQuestion q,
    bool bn,
    Map<String, String> s,
    Map<String, String> ls,
  ) {
    final attempt = _attempt;
    // Mode G key letter -> option index (list rows never carry
    // one); bounds-checked by guideKeyIndex, null when unknown.
    final correctIndex = guideKeyIndex(_answerKeyLetter, q.options.length);
    // Mode G key letter surfaces here (list rows never carry a
    // key): option text when indexed, else the letter itself —
    // so a keyed row never shows the misleading no-key note.
    final keyText = correctIndex != null
        ? q.options[correctIndex]
        : (_answerKeyLetter.isNotEmpty ? _answerKeyLetter : _keyText(q));
    final chips = <String>[ls['sourceGuideQuestion']!];
    if (keyText != null) chips.add(ls['sourceGuideKey']!);
    chips.add(ls['sourceAiExplanation']!);
    return GuideAnswerBody(
      q: q,
      attempt: attempt,
      keyText: keyText,
      correctOptionIndex: correctIndex,
      chips: chips,
      fontSize: _fontSize,
      onFontSmaller: () =>
          setState(() => _fontSize = (_fontSize - 1).clamp(12, 24)),
      onFontLarger: () =>
          setState(() => _fontSize = (_fontSize + 1).clamp(12, 24)),
      verbatimKind: _verbatimKind,
      verbatimText: _verbatimText,
      correctionNote: _correctionNote,
      guideError: _guideError,
      showExplanation: _showExplanation,
      explanationPending: _explaining,
      stepsOnly: _stepsOnly,
      onExplainDetailed: () => setState(() {
        _showExplanation = true;
        _stepsOnly = false;
      }),
      onExplainSteps: () => setState(() {
        _showExplanation = true;
        _stepsOnly = true;
      }),
      onRetry: () {
        setState(() => _loading = true);
        _load();
      },
      onAskAi: () => _openChat(q),
      subjectId: GuideAnswerHolder.subjectId,
      chapterNumber: GuideAnswerHolder.chapterNumber,
      bn: bn,
      s: s,
      ls: ls,
    );
  }
}
