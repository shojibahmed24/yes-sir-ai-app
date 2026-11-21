// Single class-resolution rule for guide/chapter cache reads:
// the saved profile class first, then an explicit route or
// selection class when the caller has one. 6 is the DOCUMENTED
// last resort only when neither source knows a class (a fresh
// install before registration, or a deep link with no saved
// profile) — it never overrides a known class, so falling back
// can never serve another class's cached rows as this class's.
import 'profile_service.dart';
import 'school_class_cache.dart';

/// Saved class, else [explicit], else the documented fallback 6.
/// A failed class read falls back the same way, never blocking
/// the caller: the caller decides whether to retry the list.
Future<int> resolveSchoolClass({int? explicit}) async {
  // B8: the startup cache answers instantly; awaiting the profile
  // read here made the first frame show Class 6.
  final cached = SchoolClassCache.value;
  if (cached != null) return cached;
  try {
    return await profileService.loadSchoolClass() ?? explicit ?? 6;
  } catch (_) {
    return explicit ?? 6;
  }
}
