// Per-part marks for one creative question (pure, no Flutter).
// The part's own printed row marks are used only when they look
// like a part mark (below the question total). Some rows carry the
// whole-question total (e.g. 10) on every part; those get no part
// mark here rather than a wrong one. When the server sends the
// normalised `marks_parts` list and it matches the visible rows
// one-to-one, that list wins.
import '../../../core/models/creative_marks_parts.dart';
import '../../../core/models/guide_bank_model.dart';

/// Rows of one stimulus group in part order ক→ঘ, stable.
/// Part letters win over natural id order: ids like
/// `...-creative-003-ga` sort ga < gha < ka < kha alphabetically,
/// which put the 3-mark part in the ক slot (marks looked wrong).
const _partIndex = {
  'ka': 0,
  'kha': 1,
  'ga': 2,
  'gha': 3,
  '1': 0,
  '2': 1,
  '3': 2,
  '4': 3,
  'ক': 0,
  'খ': 1,
  'গ': 2,
  'ঘ': 3,
};

int partOrderOf(String id) {
  final tail = id.split('-').last.toLowerCase();
  final byLetter = _partIndex[tail];
  if (byLetter != null) return byLetter;
  // `...-part-2` style.
  final m = RegExp(r'part[-_]?(\d)$').firstMatch(id.toLowerCase());
  if (m != null) return (int.tryParse(m.group(1)!) ?? 1) - 1;
  return 99;
}

List<GuideBankQuestion> idOrderedParts(List<GuideBankQuestion> group) {
  final indexed = [for (var i = 0; i < group.length; i++) (i, group[i])];
  indexed.sort((a, b) {
    final pa = partOrderOf(a.$2.id), pb = partOrderOf(b.$2.id);
    if (pa != pb) return pa.compareTo(pb);
    final c = compareIdsNatural(a.$2.id, b.$2.id);
    return c != 0 ? c : a.$1.compareTo(b.$1);
  });
  return [for (final e in indexed) e.$2];
}

/// Marks to show per part, same order as [parts]; null = show none.
List<int?> creativePartMarks(
  List<GuideBankQuestion> parts, {
  List<int>? marksParts,
  int questionTotal = 10,
}) {
  if (marksParts != null && marksParts.length == parts.length) {
    return List<int?>.of(marksParts);
  }
  return [
    for (final p in parts)
      (p.marks != null && p.marks! > 0 && p.marks! < questionTotal)
          ? p.marks
          : null,
  ];
}

/// The group's server marks_parts (first row that has one), or null.
List<int>? groupMarksParts(List<GuideBankQuestion> group) {
  for (final p in group) {
    if (p.marksParts != null) return p.marksParts;
  }
  return null;
}

/// Display order: id order when marks_parts matches the rows
/// one-to-one (ক first, so equal row marks cannot reorder parts),
/// else the marks-based order used before.
List<GuideBankQuestion> orderForDisplay(List<GuideBankQuestion> group) {
  // Always part-letter order (ক→ঘ). marks_parts is stored in that
  // order too, so index i still maps to the same part.
  return idOrderedParts(group);
}
