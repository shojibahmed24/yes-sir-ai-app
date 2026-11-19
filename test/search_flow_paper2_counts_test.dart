// Paper-II section counts: exact server totals only, unknown kept
// visible, stale runs never overwrite a newer subject.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/data/paper2_sections.dart';
import 'package:yes_sir_ai/core/services/guide_flow_count_service.dart';
import 'package:yes_sir_ai/features/learn/search_flow_paper2_counts.dart';

void main() {
  test('load reads every section once and keeps the exact totals', () async {
    final asked = <String>[];
    final svc = GuideFlowCountService(
      post: (b, {endpoint}) async {
        final section = b['section'] as String;
        asked.add(section);
        if (!section.startsWith('writing-')) return null; // unknown
        return {'found': true, 'total': 10, 'section': section};
      },
    );
    var notified = 0;
    final counts = Paper2SectionCounts(
      onChanged: () => notified++,
      service: svc,
    );
    await counts.load(schoolClass: 9);
    expect(asked.toSet(), paperTwoSections.toSet());
    expect(asked.length, paperTwoSections.length);
    expect(counts.counts['writing-letter'], 10);
    expect(counts.counts.containsKey('verbs'), isTrue);
    expect(counts.counts['verbs'], isNull);
    expect(counts.loading, isFalse);
    expect(notified, greaterThanOrEqualTo(2));
  });

  test('a zero total is kept as zero, never dropped', () async {
    final svc = GuideFlowCountService(
      post: (b, {endpoint}) async => {
        'found': true,
        'total': 0,
        'section': b['section'],
      },
    );
    final counts = Paper2SectionCounts(onChanged: () {}, service: svc);
    await counts.load(schoolClass: 10);
    expect(counts.counts.values.every((v) => v == 0), isTrue);
    expect(counts.counts.length, paperTwoSections.length);
  });

  test('clear drops the counts; a superseded load writes nothing', () async {
    final svc = GuideFlowCountService(
      post: (b, {endpoint}) async => {
        'found': true,
        'total': 5,
        'section': b['section'],
      },
    );
    final counts = Paper2SectionCounts(onChanged: () {}, service: svc);
    await counts.load(schoolClass: 9);
    expect(counts.counts['verbs'], 5);
    counts.clear();
    expect(counts.counts, isEmpty);
    expect(counts.loading, isFalse);

    final slow = counts.load(schoolClass: 9);
    counts.clear();
    await slow;
    expect(counts.counts, isEmpty, reason: 'stale run must not land');
  });
}
