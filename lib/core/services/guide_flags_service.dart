// Bulk guide-presence flags for ONE class in ONE Edge call
// (quick-load, 2026-11-21). Before this, the subject list probed each
// locked subject separately (chapters -> sets -> bank rows): up to
// three round-trips per subject, and a class with 13 locked subjects
// paid them all before Home could paint. The server now answers the
// whole class at once; null = unreachable/old server, and callers
// fall back to the per-subject probe (never a guessed flag).
import 'app_config.dart';
import 'edge_post.dart';

/// Subject id -> has a guide. Null = unknown (unreachable, bad body,
/// or a server without the guideFlags action).
Map<String, bool>? parseGuideFlagsResponse(Map<String, dynamic>? res) {
  if (res == null || res['found'] != true) return null;
  final flags = res['flags'];
  if (flags is! Map) return null;
  final out = <String, bool>{};
  flags.forEach((key, value) {
    if (value is Map) out['$key'] = value['hasGuide'] == true;
  });
  // An empty map means the class answered nothing useful (cold or
  // partial): treat it as unknown so callers fall back to the
  // per-subject probe instead of locking every subject.
  return out.isEmpty ? null : out;
}

/// One request per class; subjects without a book row are absent from
/// the reply (no book = no guide rows can exist for that class).
Future<Map<String, bool>?> loadGuideFlags(int schoolClass) async {
  if (AppConfig.guideBankEndpoint.isEmpty) return null;
  final res = await edgePost({
    'action': 'guideFlags',
    'classId': schoolClass,
  }, endpoint: AppConfig.guideBankEndpoint);
  return parseGuideFlagsResponse(res);
}
