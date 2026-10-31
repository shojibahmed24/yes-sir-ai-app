// Guide-bank cache keys + one-time migration, split out of
// guide_bank_service.dart to keep it under the 250-line limit.
// Keys are class-keyed: guide_bank_chapter_<class>_<subject>_
// <chapter> (same shape for index + sets). A class-7 chapter
// cached earlier must never be served to a class-6 student.
// Pre-v2 keys had no class segment; on first run after this
// change they are deleted (migration marker below), so no stale
// class-less row can ever be read again.
// INVALIDATION: after a new guide import (e.g. the Talimit Math
// import), call invalidateGuideBankCache() once so the next
// visit refetches fresh server rows instead of stale cache.
import 'package:shared_preferences/shared_preferences.dart';

const guideBankCacheVersion = 2;
const _versionKey = 'guide_bank_cache_version';
const _chapterPrefix = 'guide_bank_chapter_';
const _indexPrefix = 'guide_bank_index_';
const _setsPrefix = 'guide_bank_sets_';

String guideChapterKey(int schoolClass, String subject, int chapter) =>
    '$_chapterPrefix${schoolClass}_${subject}_$chapter';
String guideIndexKey(int schoolClass, String subject) =>
    '$_indexPrefix${schoolClass}_$subject';
String guideSetsKey(int schoolClass, String subject) =>
    '$_setsPrefix${schoolClass}_$subject';

bool _migrated = false;

/// One-time migration: deletes pre-v2 (class-less) keys, keeps
/// class-keyed ones. Runs at most once per process; the version
/// marker makes it once ever per install.
Future<void> ensureGuideCacheMigrated() async {
  if (_migrated) return;
  _migrated = true;
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getInt(_versionKey) == guideBankCacheVersion) return;
  final newPattern = RegExp(r'^guide_bank_(chapter|index|sets)_\d+_');
  final legacy = prefs
      .getKeys()
      .where((k) =>
          k.startsWith(_chapterPrefix) ||
          k.startsWith(_indexPrefix) ||
          k.startsWith(_setsPrefix))
      .where((k) => !newPattern.hasMatch(k))
      .toList();
  for (final k in legacy) {
    await prefs.remove(k);
  }
  await prefs.setInt(_versionKey, guideBankCacheVersion);
}

/// Drops ALL cached guide-bank rows (chapters, indexes, sets).
/// Call after a guide import; the version marker is kept, so the
/// migration above does not re-run and delete fresh keys.
Future<void> invalidateGuideBankCache() async {
  final prefs = await SharedPreferences.getInstance();
  final keys = prefs
      .getKeys()
      .where((k) =>
          k.startsWith(_chapterPrefix) ||
          k.startsWith(_indexPrefix) ||
          k.startsWith(_setsPrefix))
      .toList();
  for (final k in keys) {
    await prefs.remove(k);
  }
}
