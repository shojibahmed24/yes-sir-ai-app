// Synchronous class cache (B8).
//
// The profile class lives in SharedPreferences, so every screen that
// needed it had to await an async read and, until it resolved, painted
// the documented fallback 6 — the search screen visibly flipped from
// Class 6 to Class 9 seconds later. Hydrating this cache once at
// startup makes the saved class available on the FIRST frame.
//
// It is only ever written from the saved profile or an explicit class
// pick, so it can never fabricate a class the student did not choose.
import 'profile_service.dart';

class SchoolClassCache {
  SchoolClassCache._();

  static int? _value;

  /// Saved class, or null when the profile has none yet.
  static int? get value => _value;

  /// Save a class the user just picked (write-through).
  static void set(int? cls) {
    if (cls != null && cls >= 1) _value = cls;
  }

  /// Reads the saved class once. Failure leaves the cache empty, so
  /// callers keep their own honest fallback.
  static Future<void> hydrate() async {
    try {
      final saved = await profileService.loadSchoolClass();
      if (saved != null && saved >= 1) _value = saved;
    } catch (_) {
      // Offline/first run: stay unknown rather than guess.
    }
  }

  /// Test hook.
  static void resetForTest() => _value = null;
}
