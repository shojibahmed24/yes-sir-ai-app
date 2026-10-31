// Guide-quiz sourcing: daily + practice quizzes from keyed guide
// MCQs via the guide-bank Edge list action (chapter-bank rows) +
// per-question Mode G key resolve. Phase 2 (2026-10-31): the list
// action now returns guideError, so the pool excludes BOTH
// server-flagged error rows AND the 18 KNOWN guide-error Math
// ids (kept as the pre-deploy guard for servers that do not yet
// send the flag). The list action never returns a key index.
//  - the pool keeps only MCQ + serverHasKey + non-empty options;
//  - every selected row resolves its key through Mode G; a row
//    whose key is missing, unmapped, or out of range is DROPPED,
//    never scored with a guessed key. Unkeyed rows never enter
//    the pool. book_questions never enter (no options/answers).
// Daily: seeded by date, stratified across chapters (same day =
// same set). Practice: random, seen-set excluded (refills when
// the unseen pool runs dry). Guide sets need 5 resolved items;
// anything less means the caller falls back to the demo bank.
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/backend_models.dart';
import '../models/guide_bank_model.dart';
import 'books_service.dart';
import 'guide_bank_service.dart';
import 'question_generation.dart';
import 'structured_explanation_service.dart';

/// Option letters in Edge order (optionsToArray: ক,খ,গ,ঘ,ঙ).
const _optionLetters = ['ক', 'খ', 'গ', 'ঘ', 'ঙ'];

/// Known guide-error MCQ ids (Math class 7 pilot corrections
/// log, kind guide_error_mcq): their printed keys are wrong, so
/// they must NEVER be scored. Public so tests can assert all
/// 18 are excluded; kept alongside the server flag as the
/// pre-deploy guard for servers not yet sending guideError.
const knownGuideErrorIds = {
  'class7-math-bn-guide-ch2-p44-ex21-mcq18',
  'class7-math-bn-guide-ch2-p56-ex22b-mcq17',
  'class7-math-bn-guide-ch3-p86-mcq26',
  'class7-math-bn-guide-ch3-p87-mcq51',
  'class7-math-bn-guide-ch4-p107-mcq13',
  'class7-math-bn-guide-ch5-p125-mcq34',
  'class7-math-bn-guide-ch6-p153-ex61mcq9',
  'class7-math-bn-guide-ch7-p182-ex72mcq10',
  'class7-math-bn-guide-ch7-p182-ex72mcq11',
  'class7-math-bn-guide-ch8-p200-ex8mcq2',
  'class7-math-bn-guide-ch8-p201-ex8smcq31',
  'class7-math-bn-guide-ch9-p211-ex91smcq59',
  'class7-math-bn-guide-ch9-p211-ex91smcq61',
  'class7-math-bn-guide-ch9-p221-ex92smcq32',
  'class7-math-bn-guide-ch10-p242-ex101smcq12',
  'class7-math-bn-guide-ch10-p242-ex101smcq30',
  'class7-math-bn-guide-ch10-p249-ex102smcq26',
  'class7-math-bn-guide-ch11-p274-ex11mcq2',
};

/// Letter (ক/খ/গ/ঘ/ঙ) -> option index, or null when the letter
/// is unknown or outside the option list. Never guess.
int? guideKeyIndex(String letter, int optionCount) {
  final i = _optionLetters.indexOf(letter);
  if (i < 0 || i >= optionCount) return null;
  return i;
}

/// True when a list row may enter a scored quiz pool: MCQ with
/// a server-confirmed key and options, and neither a
/// server-flagged guide-error row nor a known guide-error id.
/// Unkeyed rows are excluded here, before any selection or
/// scoring can see them.
bool isScorableGuideMcq(GuideBankQuestion q) =>
    q.questionType == 'mcq' &&
    q.serverHasKey &&
    q.options.isNotEmpty &&
    !q.guideError &&
    !knownGuideErrorIds.contains(q.id);

/// A pool row with its textbook chapter (for stratification).
class GuideQuizCandidate {
  final GuideBankQuestion question;
  final int chapter;
  const GuideQuizCandidate(this.question, this.chapter);
}

class GuideQuizService {
  static const _seenKey = 'guide_quiz_seen_ids';
  static const _seenCap = 200;

  /// All scorable guide MCQs for one class+subject, grouped by
  /// chapter (chapter-bank rows only; set rows are model-test
  /// rows). Uses the class-keyed cached chapter lists when
  /// present, else fetches + caches via GuideBankService. Empty
  /// = no guide,
  /// unreachable, or no scorable rows — the caller falls back
  /// to the demo bank, never fabricates.
  Future<List<GuideQuizCandidate>> fetchPool({
    required String subject,
    required int schoolClass,
  }) async {
    // Textbook chapters first; when none exist for the class
    // (e.g. Talimit class-9 guides), fall back to the server's
    // guide-native chapter numbers — same numbers, second
    // system — so the pool is never empty for a missing
    // textbook list alone.
    final textbook = await booksService.chaptersForSubjectAsync(
        schoolClass, subject, true);
    List<int> numbers;
    if (textbook != null && textbook.isNotEmpty) {
      numbers = textbook.map((c) => c.number).toList();
    } else {
      final guide = await guideBankService.fetchGuideChapters(
          subject, schoolClass: schoolClass);
      if (guide == null || guide.isEmpty) return const [];
      numbers = guide.keys.toList()..sort();
    }
    final pool = <GuideQuizCandidate>[];
    for (final number in numbers) {
      final ch = number;
      final cached = await guideBankService.cachedChapter(subject,
          ch, schoolClass: schoolClass);
      final rows = cached ??
          await guideBankService.fetchChapterFromServer(
              subject, ch, schoolClass: schoolClass);
      if (rows == null) continue;
      for (final q in rows) {
        if (isScorableGuideMcq(q)) {
          pool.add(GuideQuizCandidate(q, ch));
        }
      }
    }
    return pool;
  }

  /// Resolve Mode G keys for candidates in order until [limit]
  /// scored items are built. Drops (never guesses): missing
  /// grounding, empty key, unmapped letter, out-of-range index.
  Future<List<QuizItem>> resolveKeys(
    List<GuideQuizCandidate> candidates, {
    required String subject,
    required int schoolClass,
    required bool bangla,
    required int limit,
  }) async {
    final items = <QuizItem>[];
    for (final c in candidates) {
      if (items.length >= limit) break;
      final grounding = await structuredExplanationService.resolveGuide(
        guideQuestionId: c.question.id,
        subject: subject,
        schoolClass: schoolClass,
        bangla: bangla,
      );
      final key = grounding.context?.answerKey ?? '';
      if (!grounding.found || key.isEmpty) continue;
      final idx = guideKeyIndex(key, c.question.options.length);
      if (idx == null) continue;
      items.add(QuizItem(
        id: c.question.id,
        questionBn: c.question.questionText,
        questionEn: c.question.questionText,
        options: c.question.options,
        correctIndex: idx,
      ));
    }
    return items;
  }

  /// Daily guide set: seeded by date, stratified across chapters
  /// (selectQuestions round-robin). Returns up to 5 resolved
  /// items; fewer means the caller must fall back to the bank.
  Future<List<QuizItem>> dailyGuideQuiz({
    required String subject,
    required int schoolClass,
    required bool bangla,
    required String day,
  }) async {
    final pool =
        await fetchPool(subject: subject, schoolClass: schoolClass);
    if (pool.isEmpty) return const [];
    final byId = {for (final c in pool) c.question.id: c};
    final placeholders = pool
        .map((c) => QuizItem(
              id: c.question.id,
              questionBn: c.question.questionText,
              questionEn: c.question.questionText,
              options: c.question.options,
              correctIndex: 0,
            ))
        .toList();
    final selected = questionGeneration.selectQuestions(
      pool: placeholders,
      count: 15,
      seedKey:
          questionGeneration.dailySeedKey(schoolClass, subject, day),
      chapterOf: (q) =>
          'ch${(byId[q.id]?.chapter ?? 0).toString().padLeft(2, '0')}',
    );
    final ordered = selected.map((q) => byId[q.id]!).toList();
    return resolveKeys(ordered,
        subject: subject,
        schoolClass: schoolClass,
        bangla: bangla,
        limit: 5);
  }

  /// Practice guide set: random, seen-set excluded (refills
  /// when the unseen pool runs dry). Returns up to 5 resolved
  /// items; fewer means the caller must fall back to the bank.
  Future<List<QuizItem>> practiceGuideQuiz({
    required String subject,
    required int schoolClass,
    required bool bangla,
  }) async {
    final pool =
        await fetchPool(subject: subject, schoolClass: schoolClass);
    if (pool.isEmpty) return const [];
    final seen = await _loadSeen();
    var fresh =
        pool.where((c) => !seen.contains(c.question.id)).toList();
    if (fresh.length < 5) fresh = pool;
    fresh.shuffle(Random());
    final items = await resolveKeys(fresh.take(15).toList(),
        subject: subject,
        schoolClass: schoolClass,
        bangla: bangla,
        limit: 5);
    await _saveSeen({...seen, ...items.map((q) => q.id)});
    return items;
  }

  Future<Set<String>> _loadSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_seenKey)?.toSet() ?? {};
  }

  Future<void> _saveSeen(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final list = ids.toList();
    final trimmed = list.length > _seenCap
        ? list.sublist(list.length - _seenCap)
        : list;
    await prefs.setStringList(_seenKey, trimmed);
  }
}

final guideQuizService = GuideQuizService();
