// Chapterless positional jump (Paper-II sections): the Nth
// row of a section's chapterless list, server-side section
// filter, no chapter ever sent. Fake Edge applies the
// section filter and honours offset/limit like the real
// chapterless list scope.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/services/guide_flow_jump.dart';
import 'package:yes_sir_ai/core/services/guide_flow_models.dart';

Map<String, dynamic> _row(String id, String section) => {
      'id': id,
      'questionText': 'Q $id',
      'questionType': 'gapbox',
      'options': <String>['a', 'b'],
      'marks': 1,
      'important': false,
      'setId': null,
      'hasKey': true,
      'guideError': false,
      'lesson': null,
      'section': section,
      'stimulusId': null,
      'stimulusText': null,
      'hasSolution': true,
    };

final _rows = <Map<String, dynamic>>[
  for (var i = 1; i <= 5; i++) _row('g$i', 'gapbox'),
  for (var i = 1; i <= 3; i++) _row('v$i', 'verbs'),
];

void main() {
  group('jumpToChapterlessPosition', () {
    test('Nth row of the picked section, chapterless scope', () async {
      Map<String, dynamic>? seen;
      final svc = GuideFlowJumpService(post: (body, {endpoint}) async {
        seen = body;
        final section = body['section'] as String?;
        final offset = (body['offset'] as num?)?.toInt() ?? 0;
        final limit = (body['limit'] as num?)?.toInt() ?? 20;
        final filtered =
            _rows.where((r) => r['section'] == section).toList();
        return {
          'found': true,
          'total': filtered.length,
          'questions': filtered.skip(offset).take(limit).toList(),
        };
      });
      final hit = await svc.jumpToChapterlessPosition(
          subject: 'english-2nd',
          schoolClass: 9,
          section: 'gapbox',
          position: 3);
      expect(hit.outcome, GuideFlowJumpOutcome.found);
      expect(hit.question!.id, 'g3');
      // The request carries the chapterless scope, never a chapter.
      expect(seen!['chapterless'], isTrue);
      expect(seen!.containsKey('chapter'), isFalse);
      expect(seen!['section'], 'gapbox');
      expect(seen!['offset'], 2);
      expect(seen!['limit'], 1);
      final other = await svc.jumpToChapterlessPosition(
          subject: 'english-2nd',
          schoolClass: 9,
          section: 'verbs',
          position: 2);
      expect(other.outcome, GuideFlowJumpOutcome.found);
      expect(other.question!.id, 'v2');
      final miss = await svc.jumpToChapterlessPosition(
          subject: 'english-2nd',
          schoolClass: 9,
          section: 'gapbox',
          position: 99);
      expect(miss.outcome, GuideFlowJumpOutcome.notFound);
    });

    test('pilot-columns-missing and unreachable are honest states',
        () async {
      final pending = GuideFlowJumpService(
          post: (body, {endpoint}) async =>
              {'found': false, 'reason': 'pilot-columns-missing'});
      final p = await pending.jumpToChapterlessPosition(
          subject: 'english-2nd',
          schoolClass: 9,
          section: 'gapbox',
          position: 1);
      expect(p.outcome, GuideFlowJumpOutcome.filterPending);
      final down =
          GuideFlowJumpService(post: (body, {endpoint}) async => null);
      final u = await down.jumpToChapterlessPosition(
          subject: 'english-2nd',
          schoolClass: 9,
          section: 'gapbox',
          position: 1);
      expect(u.outcome, GuideFlowJumpOutcome.unavailable);
    });
  });
}
