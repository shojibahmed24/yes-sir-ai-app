// Lesson ordering for the picker (B11).
//
// The server returns every guide `lesson` value of a chapter in DB
// order, including compilation headings ("মাস্টার ট্রেইনার প্যানেল
// কৃতক প্রণীত…", "মডেল টেস্ট — যাচাই ও মূল্যায়ন (PART 04)"). Shown
// raw, the syllabus lessons were mixed with those headings and
// near-duplicate spellings (১১.১.৩ twice) — the list looked random.
//
// This file orders the rows and flags the compilation headings so the
// UI can put them in one group at the end. Nothing is dropped: a
// value the student could reach before is still reachable.

class LessonEntry {
  const LessonEntry({
    required this.value,
    required this.title,
    required this.compilation,
    this.code,
  });

  /// The verbatim DB `lesson` value (sent back as the filter).
  final String value;

  /// The display title (may equal [value]).
  final String title;

  /// True for a block heading, not a syllabus lesson.
  final bool compilation;

  /// Numeric lesson code (e.g. '11.1.3'), when the value has one.
  final String? code;
}

const _compilationMarkers = [
  'মাস্টার ট্রেইনার',
  'মডেল টেস্ট',
  'অধিকতর অনুশীলন',
  'একাধিক অধ্যায়ের সমন্বয়',
  'সকল বোর্ড',
  'সম্ভাব্য',
  'বহুনির্বাচনি প্রশ্নব্যাংক',
  'সৃজনশীল প্রশ্নব্যাংক',
  'পরীক্ষা প্রস্তুতি',
];

final _codePrefix = RegExp(r'^\s*([0-9০-৯]+(?:\.[0-9০-৯]+)*)');
final _bnDigits = '০১২৩৪৫৬৭৮৯';

String? lessonCodeOf(String value) {
  final m = _codePrefix.firstMatch(value);
  if (m == null) return null;
  return m.group(1)!.split('').map((ch) {
    final i = _bnDigits.indexOf(ch);
    return i >= 0 ? '$i' : ch;
  }).join();
}

bool isCompilationLesson(String value) {
  if (lessonCodeOf(value) != null) return false;
  for (final marker in _compilationMarkers) {
    if (value.contains(marker)) return true;
  }
  return false;
}

int _compareCodes(String? a, String? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  final pa = a.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  final pb = b.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  for (var i = 0; i < pa.length && i < pb.length; i++) {
    if (pa[i] != pb[i]) return pa[i].compareTo(pb[i]);
  }
  return pa.length.compareTo(pb.length);
}

/// Syllabus lessons first (by their printed code), then values that
/// carry no code, then compilation headings at the very end. Within
/// each part the incoming (curated map) order is preserved as a
/// stable tie-breaker, so curated subjects keep their syllabus order.
List<LessonEntry> orderLessonEntries(Map<String, String> lessons) {
  final entries = <LessonEntry>[];
  var index = 0;
  final order = <String, int>{};
  for (final e in lessons.entries) {
    order[e.key] = index++;
    entries.add(
      LessonEntry(
        value: e.key,
        title: e.value.isEmpty ? e.key : e.value,
        compilation: isCompilationLesson(e.key),
        code: lessonCodeOf(e.key),
      ),
    );
  }
  entries.sort((a, b) {
    if (a.compilation != b.compilation) return a.compilation ? 1 : -1;
    if (a.compilation && b.compilation) {
      return (order[a.value] ?? 0).compareTo(order[b.value] ?? 0);
    }
    final byCode = _compareCodes(a.code, b.code);
    if (byCode != 0) return byCode;
    return (order[a.value] ?? 0).compareTo(order[b.value] ?? 0);
  });
  return entries;
}
