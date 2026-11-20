// L10n guard (P6): every Bangla/English page-string pair must carry
// the SAME keys, and no value may be empty, a row of question marks
// or mojibake ('???? ???' shipped once as "গাইড আছে"). This is a
// text-level check over lib/l10n/pages so a new map is covered the
// day it is added — no import list to maintain.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

class _Map {
  _Map(this.name, this.file, this.keys, this.values);
  final String name;
  final String file;
  final List<String> keys;
  final Map<String, String> values;
}

final _mapPattern =
    RegExp(r'Map<String, String>\s+(\w+)\s*=\s*\{([\s\S]*?)\n\};');
// Keys and values may be single- OR double-quoted, and a value may
// start on the next line (formatted Bangla maps do this). Only the
// first fragment of a concatenated string is read, which is enough
// to prove the key exists and its text is not decode-broken.
final _pairPattern = RegExp(
  r'''['"]((?:[^'"\\]|\\.)+)['"]\s*:\s*(?:'((?:[^'\\]|\\.)*)'|"((?:[^"\\]|\\.)*)")''',
  dotAll: true,
);

List<_Map> _readMaps() {
  final dir = Directory('lib/l10n/pages');
  final out = <_Map>[];
  for (final f in dir.listSync().whereType<File>()) {
    if (!f.path.endsWith('.dart')) continue;
    final text = f.readAsStringSync();
    for (final m in _mapPattern.allMatches(text)) {
      final values = <String, String>{};
      for (final p in _pairPattern.allMatches(m.group(2)!)) {
        values[p.group(1)!] = p.group(2) ?? p.group(3) ?? '';
      }
      out.add(_Map(m.group(1)!, f.path, values.keys.toList(), values));
    }
  }
  return out;
}

bool _isMojibake(String v) {
  final t = v.trim();
  if (t.isEmpty) return true;
  // A row of '?' is what a failed Bangla decode looks like.
  return RegExp(r'^\?+$').hasMatch(t) || t.contains('???');
}

void main() {
  final maps = _readMaps();

  test('every l10n page file defines at least one map', () {
    expect(maps, isNotEmpty);
    expect(maps.length, greaterThanOrEqualTo(40));
    // Guard against a regex that silently matches nothing: the page
    // maps together carry far more than a thousand keys.
    final total = maps.fold<int>(0, (sum, m) => sum + m.keys.length);
    expect(total, greaterThan(1000));
  });

  test('Bn/En pairs share exactly the same keys', () {
    final byBase = <String, Map<String, _Map>>{};
    for (final m in maps) {
      final base = m.name.endsWith('Bn')
          ? m.name.substring(0, m.name.length - 2)
          : m.name.endsWith('En')
              ? m.name.substring(0, m.name.length - 2)
              : m.name;
      final lang = m.name.endsWith('Bn')
          ? 'bn'
          : m.name.endsWith('En')
              ? 'en'
              : 'only';
      byBase.putIfAbsent(base, () => {})[lang] = m;
    }
    final problems = <String>[];
    byBase.forEach((base, pair) {
      final bn = pair['bn'];
      final en = pair['en'];
      if (bn == null || en == null) return;
      final missingEn = bn.keys.where((k) => !en.values.containsKey(k));
      final missingBn = en.keys.where((k) => !bn.values.containsKey(k));
      for (final k in missingEn) {
        problems.add('$base: "$k" in ${bn.name} but missing in ${en.name}');
      }
      for (final k in missingBn) {
        problems.add('$base: "$k" in ${en.name} but missing in ${bn.name}');
      }
    });
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('no empty or decode-broken string values', () {
    final bad = <String>[];
    for (final m in maps) {
      m.values.forEach((k, v) {
        if (_isMojibake(v)) bad.add('${m.file} ${m.name}["$k"] = "$v"');
      });
    }
    expect(bad, isEmpty, reason: bad.join('\n'));
  });
}
