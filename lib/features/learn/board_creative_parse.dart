// Board creative rows store the stimulus and all four parts in one
// questionText ("... ক. ... খ. ... গ. ... ঘ. ..."). This pure
// parser splits it for the board-format card; it never invents a
// part and returns null when the shape is not the printed 4-part
// pattern.
class BoardCreativePart {
  const BoardCreativePart({required this.label, required this.text});
  final String label; // ক / খ / গ / ঘ
  final String text;
}

class BoardCreativeParts {
  const BoardCreativeParts({required this.stimulus, required this.parts});
  final String stimulus;
  final List<BoardCreativePart> parts;
}

final _marker = RegExp(r'([কখগঘ])\s*[\.।]');
final _space = RegExp(r'\s');

BoardCreativeParts? parseBoardCreative(String text) {
  final matches = <RegExpMatch>[];
  for (final m in _marker.allMatches(text)) {
    final i = m.start;
    if (i == 0 || _space.hasMatch(text[i - 1])) matches.add(m);
  }
  if (matches.length < 2) return null;
  final first = matches.first.start;
  final stimulus = text.substring(0, first).trim();
  final parts = <BoardCreativePart>[];
  for (var i = 0; i < matches.length; i++) {
    final m = matches[i];
    final end = i + 1 < matches.length ? matches[i + 1].start : text.length;
    final body = text.substring(m.end, end).trim();
    if (body.isEmpty) return null;
    parts.add(BoardCreativePart(label: m.group(1)!, text: body));
  }
  return BoardCreativeParts(stimulus: stimulus, parts: parts);
}
