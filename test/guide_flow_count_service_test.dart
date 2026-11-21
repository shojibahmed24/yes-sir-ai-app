// Picker type-count service: exact server totals only, honest null
// for old servers / errors, session cache, shared in-flight calls.
import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/services/guide_flow_count_service.dart';
import 'package:yes_sir_ai/features/learn/search_flow_types.dart';

void main() {
  test('returns the server total and sends a limit-1 slim request', () async {
    final bodies = <Map<String, dynamic>>[];
    final svc = GuideFlowCountService(
      post: (b, {endpoint}) async {
        bodies.add(b);
        return {
          'found': true,
          'total': 87,
          'lesson': b['lesson'],
          'section': b['section'],
        };
      },
    );
    final n = await svc.count(
      subject: 'math',
      schoolClass: 9,
      chapter: 2,
      type: SearchFlowType.creative,
      lesson: '2.1',
    );
    expect(n, 87);
    expect(bodies.single['limit'], 1);
    expect(bodies.single['slim'], true);
    expect(bodies.single['section'], 'creative');
    expect(bodies.single['lesson'], '2.1');
  });

  test('old server (no echo) gives null, never a guessed count', () async {
    final svc = GuideFlowCountService(
      post: (b, {endpoint}) async => {'found': true, 'total': 500},
    );
    expect(
      await svc.count(
        subject: 'math',
        schoolClass: 9,
        chapter: 2,
        type: SearchFlowType.mcq,
      ),
      isNull,
    );
  });

  test('null reply, found:false and thrown errors give null', () async {
    for (final post in <GuideFlowPostFake>[
      (b, {endpoint}) async => null,
      (b, {endpoint}) async => {'found': false},
      (b, {endpoint}) async => throw Exception('net'),
    ]) {
      final svc = GuideFlowCountService(post: post);
      expect(
        await svc.count(
          subject: 'math',
          schoolClass: 9,
          chapter: 2,
          type: SearchFlowType.short,
        ),
        isNull,
      );
    }
  });

  test('a read count is cached; a failed one is retried', () async {
    var calls = 0;
    var fail = true;
    final svc = GuideFlowCountService(
      post: (b, {endpoint}) async {
        calls++;
        if (fail) return null;
        return {
          'found': true,
          'total': 5,
          'lesson': b['lesson'],
          'section': b['section'],
        };
      },
    );
    Future<int?> ask() => svc.count(
      subject: 'math',
      schoolClass: 9,
      chapter: 3,
      type: SearchFlowType.mcq,
    );
    expect(await ask(), isNull);
    fail = false;
    expect(await ask(), 5);
    expect(await ask(), 5);
    // The failed first call retries ONCE immediately (transient 5xx),
    // then the second ask succeeds: 2 + 1 = 3 posts, both later asks
    // served from cache.
    expect(calls, 3);
  });

  test('concurrent identical requests share one call', () async {
    var calls = 0;
    final svc = GuideFlowCountService(
      post: (b, {endpoint}) async {
        calls++;
        return {
          'found': true,
          'total': 9,
          'lesson': b['lesson'],
          'section': b['section'],
        };
      },
    );
    final r = await Future.wait([
      svc.count(
        subject: 's',
        schoolClass: 9,
        chapter: 1,
        type: SearchFlowType.creative,
      ),
      svc.count(
        subject: 's',
        schoolClass: 9,
        chapter: 1,
        type: SearchFlowType.creative,
      ),
    ]);
    expect(r, [9, 9]);
    expect(calls, 1);
  });

  test('countAll asks all five types', () async {
    final seen = <String>[];
    final svc = GuideFlowCountService(
      post: (b, {endpoint}) async {
        seen.add(b['section'] as String);
        return {
          'found': true,
          'total': 1,
          'lesson': b['lesson'],
          'section': b['section'],
        };
      },
    );
    final out = await svc.countAll(subject: 'math', schoolClass: 9, chapter: 4);
    expect(out.length, 5);
    expect(seen.toSet(), {
      'mcq_bank',
      'short',
      'creative',
      'practice_work',
      'textbook_exercise',
    });
  });

  test('paper2 section count is chapterless and echoes the section', () async {
    final bodies = <Map<String, dynamic>>[];
    final svc = GuideFlowCountService(
      post: (b, {endpoint}) async {
        bodies.add(b);
        return {'found': true, 'total': 41, 'section': b['section']};
      },
    );
    final n = await svc.countPaperTwoSection(
      subject: 'english-2nd',
      schoolClass: 9,
      section: 'verbs',
    );
    expect(n, 41);
    expect(bodies.single['chapterless'], true);
    expect(bodies.single.containsKey('chapter'), isFalse);
    expect(bodies.single['section'], 'verbs');
    expect(bodies.single['limit'], 1);
    expect(bodies.single['slim'], true);
  });

  test('paper2 section count: zero is real, missing echo is unknown', () async {
    final zero = GuideFlowCountService(
      post: (b, {endpoint}) async => {
        'found': true,
        'total': 0,
        'section': b['section'],
      },
    );
    expect(
      await zero.countPaperTwoSection(
        subject: 'english-2nd',
        schoolClass: 9,
        section: 'gapbox',
      ),
      0,
    );
    final old = GuideFlowCountService(
      post: (b, {endpoint}) async => {'found': true, 'total': 158},
    );
    expect(
      await old.countPaperTwoSection(
        subject: 'english-2nd',
        schoolClass: 9,
        section: 'gapbox',
      ),
      isNull,
    );
  });

  test('paper2 section counts are cached per section', () async {
    var calls = 0;
    final svc = GuideFlowCountService(
      post: (b, {endpoint}) async {
        calls++;
        return {'found': true, 'total': 7, 'section': b['section']};
      },
    );
    for (var i = 0; i < 3; i++) {
      await svc.countPaperTwoSection(
        subject: 'english-2nd',
        schoolClass: 9,
        section: 'table',
      );
    }
    expect(calls, 1);
  });
}

typedef GuideFlowPostFake =
    Future<Map<String, dynamic>?> Function(
      Map<String, dynamic> body, {
      String? endpoint,
    });
