// On-device cache for the FIRST page of a question list (B6).
//
// The list used to reload from the Edge every time the student came
// back from an answer (the memory cache lived only 3 minutes), so a
// slow connection showed skeletons again and again. The raw list
// response of the first page is stored per filter identity and
// reused for 24 hours: reopening a list paints instantly, while the
// network copy replaces it in the background on the next load.
//
// Only the server-filtered first page is cached. Scan-based paths
// (creative/client scan, set lists) are intentionally absent: their
// pages are expensive to rebuild and must never be stale.
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CachedListPage {
  const CachedListPage({required this.body, required this.savedAt});
  final Map<String, dynamic> body;
  final DateTime savedAt;
}

class GuideListDiskCache {
  static const _key = 'ys_guide_list_cache_v1';
  static const _ttl = Duration(hours: 24);
  static const _maxEntries = 40;

  /// Insertion order = LRU order (oldest first).
  Future<Map<String, dynamic>> _readAll() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeAll(Map<String, dynamic> all) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(all));
  }

  Future<CachedListPage?> read(String identity) async {
    final all = await _readAll();
    final entry = all[identity];
    if (entry is! Map) return null;
    final saved = entry['savedAt'];
    final at = saved is int ? DateTime.fromMillisecondsSinceEpoch(saved) : null;
    if (at == null || DateTime.now().difference(at) > _ttl) return null;
    final body = entry['body'];
    if (body is! Map) return null;
    return CachedListPage(body: Map<String, dynamic>.from(body), savedAt: at);
  }

  Future<void> save(String identity, Map<String, dynamic> body) async {
    final all = await _readAll();
    all.remove(identity);
    all[identity] = {
      'savedAt': DateTime.now().millisecondsSinceEpoch,
      'body': body,
    };
    while (all.length > _maxEntries) {
      all.remove(all.keys.first);
    }
    await _writeAll(all);
  }

  /// Test/support hook: drop everything.
  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}

final guideListDiskCache = GuideListDiskCache();
