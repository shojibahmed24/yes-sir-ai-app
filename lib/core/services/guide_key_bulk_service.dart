// Bulk guide-key lookup (2026-11-21): ONE Edge call for a whole model
// test (max 200 ids) instead of one Mode G call per question. Null
// means "bulk unavailable" so callers fall back to the per-question
// path; an empty map is a real answer (no keyed rows).
import '../services/app_config.dart';
import '../services/edge_post.dart';

Future<Map<String, String>?> fetchGuideKeys(List<String> ids) async {
  if (ids.isEmpty) return const {};
  if (AppConfig.guideBankEndpoint.isEmpty &&
      AppConfig.explainEndpoint.isEmpty) {
    return null;
  }
  final res = await edgePost({
    'resolveKeys': ids.take(200).toList(),
  }, endpoint: AppConfig.explainEndpoint);
  if (res == null) return null;
  final keys = res['keys'];
  if (keys is! Map) return null;
  return {
    for (final e in keys.entries)
      if (e.value is String) '${e.key}': e.value as String,
  };
}
