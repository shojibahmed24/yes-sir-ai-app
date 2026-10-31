// Pure creative-part ordering helpers (step 6, no Flutter).
// One creative question's parts share a stimulus; each part row
// carries its own marks and guide solution. Parts arrive in an
// arbitrary order, so the answer view orders them ক→খ→গ→ঘ.
// Detection is tolerant: a row whose question text does not
// start with a part letter keeps its input order after the
// lettered parts, and is labelled by position — never dropped.
import '../../../core/models/guide_bank_model.dart';

/// Canonical part letters, in display order.
const creativePartLetters = ['ক', 'খ', 'গ', 'ঘ'];

/// 0-based part index parsed from the row's leading letter, or
/// null when the text starts with anything else (or is empty).
int? creativePartIndex(GuideBankQuestion q) {
  final text = q.questionText.trimLeft();
  if (text.isEmpty) return null;
  final i = creativePartLetters.indexOf(text[0]);
  return i >= 0 ? i : null;
}

/// Tab label for a part: its parsed letter, else the letter at
/// its position in the ordered list (so an unlettered second
/// part still reads খ). Beyond ঘ, the 1-based position number.
String creativePartLabel(GuideBankQuestion q, int fallbackIndex) {
  final i = creativePartIndex(q);
  if (i != null) return creativePartLetters[i];
  if (fallbackIndex >= 0 && fallbackIndex < creativePartLetters.length) {
    return creativePartLetters[fallbackIndex];
  }
  return '${fallbackIndex + 1}';
}

/// Parts in ক→খ→গ→ঘ order (stable for duplicate letters);
/// unlettered rows keep input order after the lettered ones.
/// Missing parts are simply absent — never synthesised.
List<GuideBankQuestion> orderedCreativeParts(
  List<GuideBankQuestion> group,
) {
  final lettered = <(int, int, GuideBankQuestion)>[];
  final rest = <GuideBankQuestion>[];
  for (var i = 0; i < group.length; i++) {
    final p = creativePartIndex(group[i]);
    if (p == null) {
      rest.add(group[i]);
    } else {
      lettered.add((p, i, group[i]));
    }
  }
  lettered.sort((a, b) =>
      a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2));
  return [...lettered.map((e) => e.$3), ...rest];
}
