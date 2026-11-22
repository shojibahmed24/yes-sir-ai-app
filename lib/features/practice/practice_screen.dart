// Route: /practice. Daily quiz + weak-topic revision are REAL:
// daily starts the generated set for the user's class + subject
// (deterministic per day, guide MCQs first, bank fallback);
// by-subject cards start random practice sets (seen questions
// excluded); revision starts ONLY the user's actual wrong
// answers, newest first. With no wrong answers the revision button
// is disabled and the card says so honestly — it never launches a
// generic quiz disguised as revision.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yes_sir_ai/core/models/backend_models.dart';
import 'package:yes_sir_ai/core/services/practice_service.dart';
import 'package:yes_sir_ai/core/services/books_service.dart';
import 'package:yes_sir_ai/core/services/resolve_school_class.dart';
import 'package:yes_sir_ai/core/services/profile_service.dart';
import 'package:yes_sir_ai/core/services/progress_service.dart';
import 'package:yes_sir_ai/features/practice/practice_store.dart';
import 'package:yes_sir_ai/features/practice/widgets/guide_fallback_dialog.dart';
import 'package:yes_sir_ai/features/practice/widgets/practice_home_view.dart';
import 'package:yes_sir_ai/l10n/language_provider.dart';
import 'package:yes_sir_ai/l10n/pages/practice_strings.dart';
import '../../theme/themed_scaffold.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  // Batch 2, item 1: daily generation awaits a book fetch plus
  // per-chapter Edge lists and up to 15 sequential Mode G key
  // resolves. It used to run with no loading state, no try/catch
  // and no timeout, so any throw or slow network made the button
  // look dead. Now the button shows a spinner and disables while
  // generating, failures surface an honest error with a retry
  // action, and a 60s timeout bounds the wait. Guide-first +
  // bank-fallback semantics are unchanged (they live in
  // generateDailyQuiz, not here).
  bool _startingDaily = false;

  Future<void> _startDaily(
    BuildContext context,
    String subject,
    bool bangla,
    Map<String, String> s,
  ) async {
    if (_startingDaily) return;
    setState(() => _startingDaily = true);
    // finally clears the busy flag on EVERY exit where the screen
    // stays mounted (error, unmounted-context return, profile
    // failure); the navigation-away success path is exempt via
    // [navigated], so no setState runs after context.go.
    var navigated = false;
    try {
      final schoolClass = await profileService.loadSchoolClass() ?? 6;
      final gen = await practiceService
          .generateDailyQuiz(
            subject: subject,
            schoolClass: schoolClass,
            bangla: bangla,
          )
          .timeout(const Duration(seconds: 12));
      PracticeSession.selectedSubject = subject;
      PracticeSession.quizShortfall = gen.guideShortfall;
      PracticeSession.quizSeedKey = gen.seedKey;
      if (!context.mounted) return;
      if (gen.items.isEmpty) {
        // Guide empty: ask, never silently substitute the bank.
        // Generation is DONE, so the spinner stops here — the
        // dialog is an idle user choice, not busy work.
        if (mounted) setState(() => _startingDaily = false);
        final useBank = await showGuideFallbackDialog(context);
        if (!context.mounted) return;
        if (!useBank) return;
        PracticeSession.quizItems = practiceService.dailyQuizFor(
          subject,
          seedKey: gen.seedKey,
          count: 20,
        );
        PracticeSession.quizSource = 'bankFallback';
        PracticeSession.quizShortfall = 0;
      } else {
        PracticeSession.quizItems = gen.items;
        PracticeSession.quizSource = gen.source.name;
      }
      PracticeSession.quizIsRevision = false;
      if (!context.mounted) return;
      navigated = true;
      context.go('/quiz');
    } catch (_) {
      if (!context.mounted) return;
      // A slow/failed guide fetch must not leave the spinner running:
      // offer the bank set right away (it always exists).
      if (mounted) setState(() => _startingDaily = false);
      final useBank = await showGuideFallbackDialog(context);
      if (!context.mounted) return;
      if (!useBank) return;
      PracticeSession.quizItems = practiceService.dailyQuizFor(
        subject,
        count: 20,
      );
      PracticeSession.quizSource = 'bankFallback';
      PracticeSession.quizShortfall = 0;
      PracticeSession.quizIsRevision = false;
      PracticeSession.selectedSubject = subject;
      navigated = true;
      context.go('/quiz');
    } finally {
      if (mounted && !navigated) setState(() => _startingDaily = false);
    }
  }

  /// Random practice set for one subject: guide MCQs first
  /// (seen questions excluded, refills when the pool runs dry).
  /// A short guide set ships with its shortfall; an empty guide
  /// set asks the user about a bank set (never silent).
  /// Same hardening as _startDaily (parent follow-up): the old
  /// shape had no loading state, no try/catch and no timeout, so
  /// the by-subject cards could look dead exactly like the daily
  /// button did. The busy card shows a spinner in its trailing
  /// slot and ignores further taps until the run settles.
  String? _startingSubject;

  Future<void> _startPractice(
    BuildContext context,
    String subject,
    bool bangla,
    Map<String, String> s,
  ) async {
    if (_startingSubject != null) return;
    setState(() => _startingSubject = subject);
    // Guide throw/timeout now falls back to the bank set inside
    // generatePracticeQuiz; this catch fires only when the bank
    // fallback (or the profile read) itself fails. Busy flag
    // clears via finally on every non-navigation exit.
    var navigated = false;
    try {
      final schoolClass = await profileService.loadSchoolClass() ?? 6;
      final gen = await practiceService
          .generatePracticeQuiz(
            subject: subject,
            schoolClass: schoolClass,
            bangla: bangla,
          )
          .timeout(const Duration(seconds: 12));
      PracticeSession.selectedSubject = subject;
      PracticeSession.quizShortfall = gen.guideShortfall;
      PracticeSession.quizSeedKey = gen.seedKey;
      if (!context.mounted) return;
      if (gen.items.isEmpty) {
        // Guide empty: ask, never silently substitute the bank.
        // Generation is DONE, so the spinner stops here — the
        // dialog is an idle user choice, not busy work.
        if (mounted) setState(() => _startingSubject = null);
        final useBank = await showGuideFallbackDialog(context);
        if (!context.mounted) return;
        if (!useBank) return;
        PracticeSession.quizItems = practiceService.dailyQuizFor(
          subject,
          seedKey: gen.seedKey,
          count: 20,
        );
        PracticeSession.quizSource = 'bankFallback';
        PracticeSession.quizShortfall = 0;
      } else {
        PracticeSession.quizItems = gen.items;
        PracticeSession.quizSource = gen.source.name;
      }
      PracticeSession.quizIsRevision = false;
      if (!context.mounted) return;
      navigated = true;
      context.go('/quiz');
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s['dailyError']!),
          action: SnackBarAction(
            label: s['retry']!,
            onPressed: () => _startPractice(context, subject, bangla, s),
          ),
        ),
      );
    } finally {
      if (mounted && !navigated) setState(() => _startingSubject = null);
    }
  }

  void _startRevision(BuildContext context, List<QuizItem> items) {
    PracticeSession.quizItems = items;
    PracticeSession.quizSource = 'bankFallback';
    PracticeSession.quizShortfall = 0;
    PracticeSession.quizSeedKey = '';
    PracticeSession.quizIsRevision = true;
    context.go('/quiz');
  }

  /// Every visible subject for the current profile class (A4).
  Future<List<SubjectInfo>> _subjectList(bool bangla) async {
    final cls = await resolveSchoolClass();
    return booksService.subjectsAsync(cls, bangla);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final s = locale.languageCode == 'bn'
            ? practiceStringsBn
            : practiceStringsEn;
        final bangla = locale.languageCode == 'bn';
        return ThemedScaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/home'),
            ),
            title: Text(s['title']!),
          ),
          body: FutureBuilder<ProgressSummary>(
            future: progressService.summary(),
            builder: (context, snap) {
              final sum = snap.data ?? ProgressSummary.empty;
              return FutureBuilder<List<SubjectInfo>>(
                future: _subjectList(bangla),
                builder: (context, subSnap) => PracticeHomeView(
                  s: s,
                  bangla: bangla,
                  sum: sum,
                  subjects: subSnap.data ?? const [],
                  selectedSubject: PracticeSession.selectedSubject,
                  startingDaily: _startingDaily,
                  startingSubject: _startingSubject,
                  onDaily: () => _startDaily(
                    context,
                    PracticeSession.selectedSubject,
                    bangla,
                    s,
                  ),
                  onWeak: () => _startRevision(context, sum.weakItems),
                  onSubject: (sub) => _startPractice(context, sub, bangla, s),
                  onGuideModel: () => context.go('/guide-model-tests'),
                  onBankModel: () => context.go('/model-tests'),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
