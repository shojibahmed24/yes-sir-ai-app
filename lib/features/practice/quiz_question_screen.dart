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
import 'package:yes_sir_ai/core/services/local_store.dart';
import 'package:yes_sir_ai/core/services/practice_service.dart';
import 'package:yes_sir_ai/core/services/progress_service.dart';
import 'package:yes_sir_ai/features/practice/practice_store.dart';
import 'package:yes_sir_ai/features/practice/quiz_explanation_body.dart';
import 'package:yes_sir_ai/features/practice/widgets/practice_widgets.dart';
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
  int _index = 0, _elapsed = 0;
  Timer? _timer;
  // Phase 17 (L3): count-up pauses in background (old: kept counting).
  bool _inBackground = false;
  bool _finishing = false;
  // Explanation state per question index (live / DEMO / missing),
  // cached across Prev/Next like the answers.
  final Map<int, String> _explanations = {};
  final Map<int, String> _explanationKind = {}; // live|demo|demo-bank|missing
  final Set<int> _loadingExplanation = {};
  // Real saved state for the toggle (H3): ids from LocalStore's
  // 'saved_questions' key, loaded once and kept in sync on toggle.
  final Set<String> _savedIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _items = PracticeSession.quizItems.isNotEmpty
        ? PracticeSession.quizItems
        : practiceService.dailyQuizFor(PracticeSession.selectedSubject);
    PracticeSession.quizItems = _items;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_inBackground) setState(() => _elapsed++);
    });
    _loadSaved();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      _inBackground = state != AppLifecycleState.resumed;

  Future<void> _loadSaved() async {
    final ids = await LocalStore.savedQuestions();
    if (mounted) setState(() => _savedIds.addAll(ids));
  }

  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); _timer?.cancel(); super.dispose(); }
  QuizItem get _q => _items[_index];
  bool get _isSaved => _savedIds.contains(_q.id);
  bool get _isChecked => _checked.contains(_index);
  bool get _isLast => _index == _items.length - 1;
  String get _clock => '${(_elapsed ~/ 60).toString().padLeft(2, '0')}:${(_elapsed % 60).toString().padLeft(2, '0')}';

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    _timer?.cancel();
    var correct = 0;
    for (final e in _answers.entries) {
      if (_items[e.key].correctIndex == e.value) correct++;
    }
    final attempt = Attempt(kind: 'quiz', testId: 'quiz-${PracticeSession.selectedSubject}',
        subject: PracticeSession.selectedSubject, chapter: PracticeSession.selectedSubject,
        correct: correct, total: _items.length, seconds: _elapsed,
        date: PracticeSession.today(),
        answers: {for (final e in _answers.entries) _items[e.key].id: e.value},
        // Phase 2: persist the actual wrong items (guide items
        // included) so weak chapters + revision can use them.
        wrongItems: [for (final e in _answers.entries)
          if (_items[e.key].correctIndex != e.value) _items[e.key]]);
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
        final msg = bangla ? quizQuestionStringsBn['selectFirst']! : quizQuestionStringsEn['selectFirst']!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        return;
      }
      setState(() => _checked.add(_index));
      _loadExplanation(_index);
    } else if (_isLast) {
      _finish();
    } else {
      setState(() => _index++);
    }
  }

  /// Save toggle (H3, same pattern as lesson/chat): 'saved'
  /// snackbar only on a genuinely new save, 'removed' only on a
  /// real removal — never a false 'saved' on a duplicate tap.
  Future<void> _toggleSave(Map<String, String> s) async {
    final id = _q.id;
    if (_isSaved) {
      final removed = await LocalStore.unsaveQuestion(id);
      if (!mounted) return;
      setState(() => _savedIds.remove(id));
      if (removed) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s['unsavedMsg']!)));
    } else {
      final newlySaved = await practiceService.saveQuestion(id);
      if (!mounted) return;
      setState(() => _savedIds.add(id));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(newlySaved ? s['savedMsg']! : s['alreadySavedMsg']!)));
    }
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
    final res = await explanationService.explainQuiz(
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
      } else if (res.outcome == ExplanationOutcome.demo) {
        _explanations[index] = res.text;
        _explanationKind[index] =
            res.demoKind == 'bank' ? 'demo-bank' : 'demo';
      } else if (res.serverKeyMissing) {
        _explanationKind[index] = 'serverKeyMissing';
      } else {
        _explanationKind[index] = 'missing';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(valueListenable: languageNotifier, builder: (context, locale, _) {
      final s = locale.languageCode == 'bn' ? quizQuestionStringsBn : quizQuestionStringsEn;
      final bangla = locale.languageCode == 'bn';
      final chosen = _answers[_index];
      return ThemedScaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/practice'),
          ),
          title: Text(s['title']!),
        ),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Row(children: [Text("${s['qLabel']!} ${_index + 1}/${_items.length}", style: Theme.of(context).textTheme.headlineMedium), const Spacer(), Chip(label: Text(_clock))]),
          const SizedBox(height: 8),
          Text(practiceService.chapterOf(_q.id, bangla), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(bangla ? _q.questionBn : _q.questionEn, style: Theme.of(context).textTheme.bodyLarge))),
          const SizedBox(height: 12),
          for (int i = 0; i < _q.options.length; i++) Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OptionTile(label: bangla ? 'কখগঘ'[i] : 'ABCD'[i], text: _q.options[i], selected: chosen == i,
                correct: _isChecked ? (i == _q.correctIndex) : null,
                onTap: _isChecked ? null : () => setState(() => _answers[_index] = i)),
          ),
          if (_isChecked) ...[
            const SizedBox(height: 8),
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(chosen == _q.correctIndex ? s['correctMsg']! : s['wrongMsg']!, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              // Audit-fix B2: explanation via shared SolutionBlocks
              // (see quiz_explanation_body.dart), never raw Text.
              QuizExplanationBody(
                loading: _loadingExplanation.contains(_index),
                kind: _explanationKind[_index],
                text: _explanations[_index],
                s: s,
              ),
            ]))),
          ],
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: _index > 0 ? () => setState(() => _index--) : null, child: Text(s['prev']!))),
            const SizedBox(width: 8),
            Expanded(child: ElevatedButton(onPressed: _primary, child: Text(!_isChecked ? s['submit']! : (_isLast ? s['finish']! : s['next']!)))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () => _toggleSave(s), icon: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border), label: Text(_isSaved ? s['savedState']! : s['save']!))),
            const SizedBox(width: 8),
            Expanded(child: TextButton(onPressed: () {
              _answers.remove(_index);
              if (_isLast) { _finish(); } else { setState(() => _index++); }
            }, child: Text(s['skip']!))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextButton.icon(onPressed: () => context.go('/saved'), icon: const Icon(Icons.bookmark), label: Text(s['viewSaved']!))),
          ]),
        ]),
      );
    });
  }
}
