// English reader scan cache (2026-11-21): a cached scan opens without
// a network scan, a failed live scan never overwrites the cache, and
// an empty/failed scan is never cached.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yes_sir_ai/core/models/guide_bank_model.dart';
import 'package:yes_sir_ai/core/services/english_reader_service.dart';
import 'package:yes_sir_ai/core/services/english_set_scan.dart';
import 'package:yes_sir_ai/core/services/guide_bank_disk_cache.dart';

EnglishSetScanService _scan({
  required List<GuideBankQuestion>? rows,
  int? failAtCall,
  void Function()? onCall,
}) {
  var calls = 0;
  return EnglishSetScanService(
    fetchSets: (subject, {schoolClass = 9}) async {
      calls++;
      onCall?.call();
      if (failAtCall != null && calls >= failAtCall) return null;
      return const [
        GuideModelSetInfo(setId: 'set-1', totalCount: 1, keyedCount: 1),
      ];
    },
    fetchSetRows: (subject, setId, {schoolClass = 9}) async => rows,
    fetchBankRows: (subject, {schoolClass = 9}) async =>
        const <GuideBankQuestion>[],
  );
}

const _poemRow = GuideBankQuestion(
  id: 'poem-1',
  questionText: 'A poem',
  questionType: 'poem',
  section: 'poem',
  stimulusRef: 'p1',
);

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('english_swr'));
  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('a live scan is written to disk, the next open serves it', () async {
    final cache = GuideBankDiskCache(rootOverride: dir);
    final first = EnglishReaderService(
      scan: _scan(rows: const [_poemRow]),
      cache: cache,
    );
    final live = await first.load(
      const EnglishReaderRequest(kind: EnglishReaderKind.poem, schoolClass: 9),
    );
    expect(live, isNotNull);
    expect(live!.totalQuestions, 1, reason: 'the poem row is grouped');

    // Second service instance: its scan would fail, so only the disk
    // cache can satisfy the open.
    final second = EnglishReaderService(
      scan: _scan(rows: null, failAtCall: 1),
      cache: GuideBankDiskCache(rootOverride: dir),
    );
    final cached = await second.load(
      const EnglishReaderRequest(kind: EnglishReaderKind.poem, schoolClass: 9),
    );
    expect(cached, isNotNull);
    expect(cached!.totalQuestions, 1);
  });

  test(
    'a failed scan with no cache stays unavailable, never empty data',
    () async {
      final svc = EnglishReaderService(
        scan: _scan(rows: null, failAtCall: 1),
        cache: GuideBankDiskCache(rootOverride: dir),
      );
      final data = await svc.load(
        const EnglishReaderRequest(
          kind: EnglishReaderKind.poem,
          schoolClass: 9,
        ),
      );
      expect(data, isNull);
    },
  );
}
