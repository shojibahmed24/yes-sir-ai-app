// Creative-pattern rule (user order 2026-11-08): the creative
// form follows the PATTERN — stimulus + 4 parts + marks 1,2,3,4
// — in ANY subject or class, never a subject or section name.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/guide_bank_model.dart';
import 'package:yes_sir_ai/core/services/guide_flow_jump.dart';
import 'package:yes_sir_ai/core/services/guide_flow_list_service.dart';
import 'package:yes_sir_ai/core/services/guide_flow_creative_scan.dart';
import 'package:yes_sir_ai/features/learn/search_flow_types.dart';
import 'package:yes_sir_ai/features/learn/widgets/guide_creative_groups.dart';
import 'package:yes_sir_ai/features/learn/widgets/guide_creative_parts.dart';

GuideBankQuestion _q(
  String id,
  String type, {
  String? sid,
  int? marks,
  String? lesson,
}) => GuideBankQuestion(
  id: id,
  questionText: 'q $id',
  questionType: type,
  stimulusId: sid,
  marks: marks,
  lesson: lesson,
);

Map<String, dynamic> _row(
  String id,
  String type, {
  String? sid,
  int? marks,
  String? lesson,
  String? section,
}) => {
  'id': id,
  'questionText': 'Q $id',
  'questionType': type,
  'options': <String>[],
  'marks': marks,
  'important': false,
  'setId': null,
  'hasKey': true,
  'guideError': false,
  'lesson': lesson,
  'section': section,
  'stimulusId': sid,
  'stimulusText': sid == null ? null : 'stim $sid',
  'hasSolution': true,
};

/// Mixed chapter: creative rows under three different sections,
/// a passage-MCQ group sharing one stimulus, and plain rows.
final _chapterRows = <Map<String, dynamic>>[
  _row('c1', 'creative', sid: 's1', marks: 1, section: 'creative'),
  _row('c2', 'creative', sid: 's1', marks: 2, section: 'creative'),
  _row('c3', 'creative', sid: 's1', marks: 3, section: 'creative'),
  _row('c4', 'creative', sid: 's1', marks: 4, section: 'creative'),
  _row(
    'm1',
    'chapter_model_creative',
    sid: 's2',
    marks: 1,
    section: 'chapter_model',
  ),
  _row(
    'm2',
    'chapter_model_creative',
    sid: 's2',
    marks: 2,
    section: 'chapter_model',
  ),
  _row(
    'm3',
    'chapter_model_creative',
    sid: 's2',
    marks: 3,
    section: 'chapter_model',
  ),
  _row(
    'm4',
    'chapter_model_creative',
    sid: 's2',
    marks: 4,
    section: 'chapter_model',
  ),
  _row('b1', 'board_creative', sid: 's3', marks: 1, section: 'board'),
  _row('b2', 'board_creative', sid: 's3', marks: 2, section: 'board'),
  _row('b3', 'board_creative', sid: 's3', marks: 3, section: 'board'),
  _row('b4', 'board_creative', sid: 's3', marks: 4, section: 'board'),
  _row('p1', 'mcq', sid: 'pass1', marks: 1, section: 'mcq_bank'),
  _row('p2', 'mcq', sid: 'pass1', marks: 1, section: 'mcq_bank'),
  _row('p3', 'mcq', sid: 'pass1', marks: 1, section: 'mcq_bank'),
  _row('p4', 'mcq', sid: 'pass1', marks: 1, section: 'mcq_bank'),
  _row('x1', 'short', section: 'short'),
  _row('x2', 'mcq', section: 'mcq_bank'),
];

/// Unfiltered chapter fake: ignores section/lesson, pages raw.
Future<Map<String, dynamic>?> _chapterServer(
  Map<String, dynamic> body, {
  String? endpoint,
}) async {
  final offset = (body['offset'] as num?)?.toInt() ?? 0;
  final limit = (body['limit'] as num?)?.toInt() ?? 20;
  return {
    'found': true,
    'total': _chapterRows.length,
    'questions': _chapterRows.skip(offset).take(limit).toList(),
  };
}

void main() {
  test('family types: creative variants count, other types do not', () {
    expect(isCreativeFamilyType('creative'), isTrue);
    expect(isCreativeFamilyType('chapter_model_creative'), isTrue);
    expect(isCreativeFamilyType('special_model_creative'), isTrue);
    expect(isCreativeFamilyType('board_creative'), isTrue);
    expect(isCreativeFamilyType('mcq'), isFalse);
    expect(isCreativeFamilyType('short'), isFalse);
    expect(isCreativeFamilyType('cq'), isFalse);
  });

  test('pattern group: exactly 4 parts with marks 1-4', () {
    final parts = [
      _q('a', 'creative', marks: 3),
      _q('b', 'creative', marks: 1),
      _q('c', 'creative', marks: 4),
      _q('d', 'creative', marks: 2),
    ];
    expect(isCreativePatternGroup(parts), isTrue);
    expect(isCreativePatternGroup(parts.sublist(0, 3)), isFalse);
    expect(
      isCreativePatternGroup([
        _q('a', 'creative', marks: 1),
        _q('b', 'creative'),
      ]),
      isFalse,
    );
    // Passage MCQs: 4 parts sharing a stimulus but marks 1,1,1,1.
    expect(
      isCreativePatternGroup([
        for (var i = 0; i < 4; i++) _q('p$i', 'mcq', marks: 1),
      ]),
      isFalse,
    );
  });

  test('grouping: family rows group, passage MCQs stay singletons', () {
    final rows = [
      for (var i = 0; i < _chapterRows.length; i++)
        (i, GuideBankQuestion.fromServerJson(_chapterRows[i])),
    ];
    final groups = groupQuestionRows(rows);
    // 3 pattern groups (s1, s2, s3) + 4 MCQ singletons + 2 plain.
    expect(groups.length, 3 + 4 + 2);
    final grouped = groups.where((g) => g.stimulusId != null).toList();
    expect(grouped.length, 3);
    expect(grouped.map((g) => g.parts.length), [4, 4, 4]);
    expect(grouped.map((g) => g.stimulusId), ['s1', 's2', 's3']);
  });

  test('pattern scan: finds family rows across sections, skips MCQs', () async {
    final page = await guideFlowCreativePatternPage(
      fetch: _chapterServer,
      subject: 'bgs',
      schoolClass: 9,
      chapter: 1,
      lesson: null,
      scanOffset: 0,
    );
    expect(page.mode, GuideFlowMode.clientFiltered);
    // B2: the first display page is 10 rows; the rest arrive on the
    // next call (auto-paged on scroll).
    expect(page.rows.map((r) => r.id), [
      'c1',
      'c2',
      'c3',
      'c4',
      'm1',
      'm2',
      'm3',
      'm4',
      'b1',
      'b2',
    ]);
    expect(page.hasMore, isTrue);
  });

  test('pattern scan: lesson filter matches client-side', () async {
    Future<Map<String, dynamic>?> lessonServer(
      Map<String, dynamic> body, {
      String? endpoint,
    }) async {
      final rows = _chapterRows.map((r) => {...r, 'lesson': '2.1'}).toList();
      final offset = (body['offset'] as num?)?.toInt() ?? 0;
      final limit = (body['limit'] as num?)?.toInt() ?? 20;
      return {
        'found': true,
        'total': rows.length,
        'questions': rows.skip(offset).take(limit).toList(),
      };
    }

    final page = await guideFlowCreativePatternPage(
      fetch: lessonServer,
      subject: 'bgs',
      schoolClass: 9,
      chapter: 1,
      lesson: '2.1',
      scanOffset: 0,
    );
    expect(page.rows.length, 10);
    final other = await guideFlowCreativePatternPage(
      fetch: lessonServer,
      subject: 'bgs',
      schoolClass: 9,
      chapter: 1,
      lesson: '9.9',
      scanOffset: 0,
    );
    expect(other.rows, isEmpty);
  });

  test(
    'service: creative type uses the pattern scan, not one section',
    () async {
      final svc = GuideFlowListService(post: _chapterServer);
      final page = await svc.fetchPage(
        subject: 'bgs',
        schoolClass: 9,
        chapter: 1,
        type: SearchFlowType.creative,
      );
      expect(page.mode, GuideFlowMode.clientFiltered);
      expect(page.rows.length, 10);
      expect(page.rows.map((r) => r.id).toSet(), {
        'c1',
        'c2',
        'c3',
        'c4',
        'm1',
        'm2',
        'm3',
        'm4',
        'b1',
        'b2',
      });
    },
  );

  test('jump: creative position counts pattern rows only', () async {
    final svc = GuideFlowJumpService(post: _chapterServer);
    final jump = await svc.jumpToPosition(
      subject: 'bgs',
      schoolClass: 9,
      chapter: 1,
      type: SearchFlowType.creative,
      lesson: null,
      position: 5,
    );
    expect(jump.outcome, GuideFlowJumpOutcome.found);
    expect(jump.question?.id, 'm1');
  });
}
