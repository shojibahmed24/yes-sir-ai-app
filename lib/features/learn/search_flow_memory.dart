// Remembers the last search-flow picks (B10).
//
// The screen is a single route, so the phone's back button leaves it
// and re-entering used to build a fresh controller with the default
// subject 'math' — a student who was on Biology / chapter 1 came back
// to a maths chapter list. This holder keeps the working picks across
// route rebuilds (no persistence needed: it is per app run).
class SearchFlowMemory {
  SearchFlowMemory._();

  static int? schoolClass;
  static String? subject;
  static String? source;
  static int? chapter;
  static String? lesson;

  static void remember({
    required int? schoolClass,
    required String subject,
    required String source,
    required int? chapter,
    required String? lesson,
  }) {
    SearchFlowMemory.schoolClass = schoolClass;
    SearchFlowMemory.subject = subject;
    SearchFlowMemory.source = source;
    SearchFlowMemory.chapter = chapter;
    SearchFlowMemory.lesson = lesson;
  }

  /// True when a previous visit has picks worth restoring.
  static bool get hasPicks => subject != null;
}
