// Class choices for the search flow, one source of truth.
// The picker used to offer only {6, 7, currently-saved}, which made
// classes 1–5 and 8–10 unreachable even though the product covers
// 1–10. The current class is always included (defensively) so a
// server-side class outside 1–10 can never leave the dropdown with
// an unmatched value.
List<int> classChoices(int? current) {
  final out = <int>[for (var c = 1; c <= 10; c++) c];
  if (current != null && !out.contains(current)) out.add(current);
  out.sort();
  return out;
}
