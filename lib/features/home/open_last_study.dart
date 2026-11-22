// "আগের পড়া চালিয়ে যাও" target (C10/D6).
//
// One tap must resume the study itself, not ask the student to pick
// everything again:
//   1. the exact question that was open (fetched by id, verbatim row)
//   2. else that lesson's hub (its question types, with real counts)
//   3. else the picker, already positioned on the chapter
//
// Any failure falls through to the next step, so the button is never
// a dead end.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/guide_bank_model.dart';
import '../../core/services/app_config.dart';
import '../../core/services/edge_post.dart';
import '../../core/services/guide_bank_fetch.dart';
import '../../core/services/resolve_school_class.dart';
import '../../core/services/school_class_cache.dart';
import '../../l10n/language_provider.dart';
import '../learn/guide_answer_holder.dart';
import '../learn/last_study.dart';
import '../learn/lesson_hub_route.dart';

Future<void> openLastStudy(BuildContext context, LastStudy study) async {
  final cls = study.schoolClass;
  final classQuery = cls == null ? '' : '&class=$cls';

  // 1) The exact question, when one was open.
  final id = study.questionId;
  if (id != null && id.isNotEmpty && AppConfig.guideBankEndpoint.isNotEmpty) {
    try {
      final full = await fetchFullRowById(
        post: (body, {endpoint}) =>
            edgePost(body, endpoint: AppConfig.guideBankEndpoint),
        id: id,
      ).timeout(const Duration(seconds: 4));
      if (full != null && context.mounted) {
        GuideAnswerHolder.set(
          q: GuideBankQuestion.fromServerJson(full),
          subject: study.subject,
          chapter: study.chapter,
          schoolClass: cls ?? 6,
          returnTo: '/home',
        );
        context.go('/guide-answer');
        return;
      }
    } catch (_) {
      // Fall through to the lesson hub.
    }
  }

  // 2) The lesson hub: types + counts for that lesson.
  if (context.mounted) {
    if (study.lesson != null && study.lesson!.isNotEmpty) {
      context.go(
        lessonHubRoute(
          subject: study.subject,
          schoolClass: cls ?? 6,
          chapter: study.chapter,
          lesson: study.lesson,
          title: study.lesson!,
        ),
      );
      return;
    }
    // 3) The picker, positioned on the chapter.
    context.go(
      '/search-flow?subject=${study.subject}&chapter=${study.chapter}'
      '$classQuery',
    );
  }
}

/// Opens ONE recent question by its id (D7).
///
/// Entries are 'subject|chapter|id|snippet'. The row used to open the
/// chapter picker, so the student had to find the question again. It
/// now fetches that exact row and opens its answer; when the row
/// cannot be fetched, an honest message says so.
Future<void> openRecentQuestion(BuildContext context, String entry) async {
  final p = entry.split('|');
  final subject = p.isNotEmpty ? p[0] : '';
  final chapter = p.length > 1 ? int.tryParse(p[1]) ?? 1 : 1;
  final id = p.length > 2 ? p[2] : '';
  if (subject.isEmpty || id.isEmpty) return;
  final cls = SchoolClassCache.value ?? await resolveSchoolClass();
  if (!context.mounted) return;
  try {
    final full = AppConfig.guideBankEndpoint.isEmpty
        ? null
        : await fetchFullRowById(
            post: (body, {endpoint}) =>
                edgePost(body, endpoint: AppConfig.guideBankEndpoint),
            id: id,
          ).timeout(const Duration(seconds: 5));
    if (!context.mounted) return;
    if (full == null) {
      _openFailed(context);
      return;
    }
    GuideAnswerHolder.set(
      q: GuideBankQuestion.fromServerJson(full),
      subject: subject,
      chapter: chapter,
      schoolClass: cls,
      returnTo: '/home',
    );
    context.go('/guide-answer');
  } catch (_) {
    if (context.mounted) _openFailed(context);
  }
}

void _openFailed(BuildContext context) {
  final bn = languageNotifier.value.languageCode == 'bn';
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        bn
            ? 'প্রশ্নটি এখন খোলা যাচ্ছে না — ইন্টারনেট দেখে আবার চেষ্টা করুন।'
            : 'Could not open that question — check the connection.',
      ),
      duration: const Duration(seconds: 3),
    ),
  );
}
