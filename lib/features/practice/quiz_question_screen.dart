// Route: /quiz. Tap option -> Submit checks it -> Next/Prev
// navigate, Finish saves and goes to results. Elapsed time counts
// up, stops on finish. 'স্যারের সহজ ব্যাখ্যা' comes from
// explanation_service: book-grounded Edge AI, a labelled DEMO
// fallback with no server path, never a substituted guess.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yes_sir_ai/core/models/backend_models.dart';
import 'package:yes_sir_ai/core/services/explanation_service.dart';
import 'package:yes_sir_ai/core/services/practice_service.dart';
import 'package:yes_sir_ai/core/services/progress_service.dart';
import 'package:yes_sir_ai/core/services/quiz_explanation_service.dart';
import 'package:yes_sir_ai/features/practice/practice_store.dart';
import 'package:yes_sir_ai/features/practice/quiz_explanation_body.dart';
import 'package:yes_sir_ai/features/practice/widgets/practice_widgets.dart';
import 'package:yes_sir_ai/features/practice/widgets/option_letter.dart';
import 'package:yes_sir_ai/features/practice/widgets/quiz_footer_actions.dart';
import 'package:yes_sir_ai/features/practice/widgets/quiz_question_header.dart';
import 'package:yes_sir_ai/features/practice/widgets/quiz_source_header.dart';
import 'package:yes_sir_ai/l10n/language_provider.dart';
import 'package:yes_sir_ai/l10n/pages/quiz_question_strings.dart';
import '../../theme/themed_scaffold.dart';

class QuizQuestionScreen extends StatefulWidget {
  const QuizQuestionScreen({super.key});
  @override
  State<QuizQuestionScreen> createState() => _QuizQuestionScreenState();
}

class _QuizQuestionScreenState extends State<QuizQuestionScreen>
    with WidgetsBindingObserver {
  late List<QuizItem> _items;
  final Map<int, int> _answers = {};
  final Set<int> _checked = {};
  int _index = 0;
  final ValueNotifier<int> _elapsed = ValueNotifier<int>(0);
  Timer? _timer;
  // Phase 17 (L3): count-up pauses in background (old: kept counting).
  bool _inBackground = false;
  bool _finishing = false;
  // Explanation state per question index (live / DEMO / missing),
  // cached across Prev/Next like the answers.
  final Map<int, String> _explanations = {};
  final Map<int, String> _explanationKind = {}; // live|demo|demo-bank|missing
  // Attribution per index, from the Edge response (see
  // GenResult); cleared with the other per-question state on
  // bank-switch, so a stale label never sticks to a new item.
  final Map<int, String> _explanationProvider = {};
  final Map<int, String?> _explanationModel = {};
  final Set<int> _loadingExplanation = {};
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (PracticeSession.quizItems.isEmpty) {
      // Deep-link fallback: a bank set, labelled as such.
      PracticeSession.quizItems = practiceService.dailyQuizFor(
        PracticeSession.selectedSubject,
      );
      PracticeSession.quizSource = 'bankFallback';
      PracticeSession.quizShortfall = 0;
    }
    _items = PracticeSession.quizItems;
    PracticeSession.quizItems = _items;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_inBackground) _elapsed.value++;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      _inBackground = state != AppLifecycleState.resumed;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _elapsed.dispose();
    super.dispose();
  }

  QuizItem get _q => _items[_index];
  bool get _isChecked => _checked.contains(_index);
  bool get _isLast => _index == _items.length - 1;

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    _timer?.cancel();
    var correct = 0;
    for (final e in _answers.entries) {
      if (_items[e.key].isCorrect(e.value)) correct++;
    }
    final attempt = Attempt(
      kind: 'quiz',
      testId: 'quiz-${PracticeSession.selectedSubject}',
      subject: PracticeSession.selectedSubject,
      // Chapter is not known at quiz level; the subject id used to
      // be written here, corrupting the saved attempt record.
      chapter: '',
      correct: correct,
      total: _items.length,
      seconds: _elapsed.value,
      date: PracticeSession.today(),
      answers: {for (final e in _answers.entries) _items[e.key].id: e.value},
      // Phase 2: persist the actual wrong items (guide items
      // included) so weak chapters + revision can use them.
      wrongItems: [
        for (final e in _answers.entries)
          if (!_items[e.key].isCorrect(e.value)) _items[e.key],
      ],
    );
    await practiceService.recordAttempt(attempt);
    // Phase 17 (L8): best-effort server progress write, local first.
    await progressService.syncToServer();
    PracticeSession.lastItems = _items;
    if (mounted) context.go('/quiz-results');
  }

  void _primary() {
    if (!_isChecked) {
      if (!_answers.containsKey(_index)) {
        final bangla = languageNotifier.value.languageCode == 'bn';
        final msg = bangla
            ? quizQuestionStringsBn['selectFirst']!
            : quizQuestionStringsEn['selectFirst']!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
        return;
      }
      setState(() => _checked.add(_index));
      _loadExplanation(_index);
    } else if (_isLast) {
      _confirmFinish();
    } else {
      setState(() => _index++);
    }
  }

  /// Q4: finishing with unanswered questions asks first — the old
  /// Finish submitted silently and the student lost easy marks.
  Future<void> _confirmFinish() async {
    final unanswered = _items.length - _answers.length;
    if (unanswered <= 0) {
      _finish();
      return;
    }
    final s = isBangla ? quizQuestionStringsBn : quizQuestionStringsEn;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s['finishTitle']!),
        content: Text(s['finishBody']!.replaceFirst('{n}', '$unanswered')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s['stay']!),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s['submitNow']!),
          ),
        ],
      ),
    );
    if (go == true && mounted) await _finish();
  }

  /// Fetches 'স্যারের সহজ ব্যাখ্যা' for one checked question.
  /// Live-but-unmatched stays 'missing' (DEMO bank never substituted).
  Future<void> _loadExplanation(int index) async {
    if (_explanations.containsKey(index) ||
        _explanationKind.containsKey(index) ||
        _loadingExplanation.contains(index)) {
      return;
    }
    setState(() => _loadingExplanation.add(index));
    final bangla = languageNotifier.value.languageCode == 'bn';
    final res = await quizExplanationService.explainQuiz(
      item: _items[index],
      subject: PracticeSession.selectedSubject,
      bangla: bangla,
    );
    if (!mounted) return;
    setState(() {
      _loadingExplanation.remove(index);
      if (res.outcome == ExplanationOutcome.live) {
        _explanations[index] = res.text;
        _explanationKind[index] = 'live';
        _explanationProvider[index] = res.aiProvider;
        _explanationModel[index] = res.aiModel;
      } else if (res.outcome == ExplanationOutcome.demo) {
        _explanations[index] = res.text;
        _explanationKind[index] = res.demoKind == 'bank' ? 'demo-bank' : 'demo';
      } else if (res.serverKeyMissing) {
        _explanationKind[index] = 'serverKeyMissing';
      } else if (res.guideMissing) {
        _explanationKind[index] = 'guideMissing';
      } else {
        _explanationKind[index] = 'missing';
      }
    });
  }

  /// Bank button (short guide set): rebuild the set from the
  /// bank with the same seed and reset all per-question state.
  void _switchToBank() {
    final items = practiceService.dailyQuizFor(
      PracticeSession.selectedSubject,
      seedKey: PracticeSession.quizSeedKey,
      count: 20,
    );
    PracticeSession.quizItems = items;
    PracticeSession.quizSource = 'bankFallback';
    PracticeSession.quizShortfall = 0;
    setState(() {
      _items = items;
      _answers.clear();
      _checked.clear();
      _explanations.clear();
      _explanationKind.clear();
      _explanationProvider.clear();
      _explanationModel.clear();
      _loadingExplanation.clear();
      _index = 0;
      _elapsed.value = 0;
    });
  }

  /// Mid-attempt exit: answers live only in memory, so leaving without
  /// asking silently discarded the run.
  Future<void> _confirmLeave(
    BuildContext context,
    Map<String, String> s,
  ) async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s['leaveTitle']!),
        content: Text(s['leaveBody']!),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s['stay']!),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s['leave']!),
          ),
        ],
      ),
    );
    if (leave == true && context.mounted) {
      _timer?.cancel();
      context.go('/practice');
    }
  }

  /// Question palette (Q3): every question at a glance — answered,
  /// unanswered and current — and a direct jump without paging.
  void _openPalette(BuildContext context, Map<String, String> s) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) {
        final answered = _answers.length;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s['paletteTitle']!,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  '${s['answered']!.replaceFirst('{n}', '$answered')} · '
                  '${s['unanswered']!.replaceFirst('{n}', '${_items.length - answered}')}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: GridView.count(
                    crossAxisCount: 6,
                    shrinkWrap: true,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: [
                      for (var i = 0; i < _items.length; i++)
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            Navigator.pop(sheet);
                            setState(() => _index = i);
                          },
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: i == _index
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer
                                  : _answers.containsKey(i)
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                              border: Border.all(
                                color: i == _index
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                                width: i == _index ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _answers.containsKey(i) && i != _index
                                    ? Colors.white
                                    : null,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final s = locale.languageCode == 'bn'
            ? quizQuestionStringsBn
            : quizQuestionStringsEn;
        final bangla = locale.languageCode == 'bn';
        final chosen = _answers[_index];
        return ThemedScaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              // Leaving mid-attempt loses every answer. Ask first.
              onPressed: () => _confirmLeave(context, s),
            ),
            title: Text(s['title']!),
            actions: [
              IconButton(
                icon: const Icon(Icons.grid_view_rounded),
                tooltip: s['paletteTitle']!,
                onPressed: () => _openPalette(context, s),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              QuizSourceHeader(
                source: PracticeSession.quizSource,
                shortfall: PracticeSession.quizShortfall,
                count: _items.length,
                isRevision: PracticeSession.quizIsRevision,
                s: s,
                onBankSet: _switchToBank,
              ),
              const SizedBox(height: 8),
              QuizQuestionHeader(
                label: "${s['qLabel']!} ${_index + 1}/${_items.length}",
                progress: (_index + 1) / _items.length,
                elapsed: _elapsed,
                chapter: practiceService.chapterOf(_q.id, bangla),
              ),
              QuizQuestionCard(
                item: _q,
                bangla: bangla,
                hint: s['multiKeyHint']!,
              ),
              const SizedBox(height: 12),
              for (int i = 0; i < _q.options.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OptionTile(
                    label: optionLetter(i, bangla),
                    text: _q.options[i],
                    selected: chosen == i,
                    correct: _isChecked ? _q.isCorrect(i) : null,
                    onTap: _isChecked
                        ? null
                        : () => setState(() => _answers[_index] = i),
                  ),
                ),
              if (_isChecked) ...[
                const SizedBox(height: 8),
                QuizCheckedCard(
                  correct: chosen != null && _q.isCorrect(chosen),
                  s: s,
                  acceptedAnswers: _q.acceptedOptionTexts,
                  loading: _loadingExplanation.contains(_index),
                  kind: _explanationKind[_index],
                  text: _explanations[_index],
                  aiProvider: _explanationProvider[_index] ?? 'unknown',
                  aiModel: _explanationModel[_index],
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 52,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _index > 0
                          ? () => setState(() => _index--)
                          : null,
                      child: const Icon(Icons.arrow_back),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _primary,
                      child: Text(
                        !_isChecked
                            ? s['submit']!
                            : (_isLast ? s['finish']! : s['next']!),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              QuizFooterActions(
                questionId: _q.id,
                s: s,
                onSkip: () {
                  _answers.remove(_index);
                  if (_isLast) {
                    _finish();
                  } else {
                    setState(() => _index++);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
