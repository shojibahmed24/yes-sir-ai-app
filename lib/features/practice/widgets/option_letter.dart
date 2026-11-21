// Option letter for a question row. A server item may carry five or
// more options; the old `'কখগঘ'[i]` threw RangeError at i == 4 and
// crashed the quiz. Bangla letters first, then a numeric fallback —
// never a crash, never a wrong letter.
String optionLetter(int index, bool bangla) {
  const banglaLetters = 'কখগঘঙচছজঝঞটঠডঢণতথদধনপফবভমযরলশষসহ';
  const latinLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  if (index < 0) return '?';
  final letters = bangla ? banglaLetters : latinLetters;
  if (index < letters.length) return letters[index];
  return '${index + 1}';
}
