// Step 7 split (keeps search_flow_list_screen.dart under the
// 250-line cap): the new-flow list URL + the two guide-answer
// openings from that list. The list URL carries the exact
// filters (subject/class/source/chapter/type/lesson/question
// number); paging itself restarts at the first 20 on return —
// the holder carries filters, not scroll/load-more state.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/guide_bank_model.dart';
import '../../core/services/app_config.dart';
import '../../core/services/guide_bank_service.dart';
import 'guide_answer_holder.dart';

String searchFlowListUrl({
  required String subjectId,
  required int schoolClass,
  required String source,
  required int chapterNumber,
  required String typeName,
  String? lesson,
  int? questionNumber,
}) {
  final q = StringBuffer('/search-flow-list?subject=$subjectId'
      '&class=$schoolClass&source=$source'
      '&chapter=$chapterNumber&type=$typeName');
  if (lesson != null) q.write('&lesson=${Uri.encodeComponent(lesson)}');
  if (questionNumber != null) q.write('&questionNumber=$questionNumber');
  return q.toString();
}

bool _unlocked(bool isPremium, int index) =>
    guideBankService.isUnlocked(
        isPremium: isPremium, index: index,
        freeLimit: AppConfig.freeGuideLimit);

/// Single-question open: holder.set() + /guide-answer, with
/// returnTo pointing back at this list.
void openSearchFlowGuideAnswer(
  BuildContext context, {
  required bool isPremium,
  required int index,
  required GuideBankQuestion q,
  required String subjectId,
  required int chapterNumber,
  required int schoolClass,
  required String returnTo,
}) {
  if (!_unlocked(isPremium, index)) {
    context.go('/premium');
    return;
  }
  GuideAnswerHolder.set(q: q, subject: subjectId,
      chapter: chapterNumber, schoolClass: schoolClass,
      returnTo: returnTo);
  context.go('/guide-answer');
}

/// Fix A: creative group open — the exact Step 6 contract
/// (all loaded parts of the stimulus via route extra). The
/// paywall gate is the first part's index, as for singles.
void openSearchFlowGuideGroupAnswer(
  BuildContext context, {
  required bool isPremium,
  required int firstIndex,
  required List<GuideBankQuestion> parts,
  required String stimulusText,
  required String subjectId,
  required int chapterNumber,
  required int schoolClass,
  required String returnTo,
}) {
  if (!_unlocked(isPremium, firstIndex)) {
    context.go('/premium');
    return;
  }
  context.go('/guide-answer', extra: {
    'group': parts,
    'stimulusText': stimulusText,
    'subjectId': subjectId,
    'chapterNumber': chapterNumber,
    'schoolClass': schoolClass,
    'returnTo': returnTo,
  });
}
