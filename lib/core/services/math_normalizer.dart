// Converts plain-text / Unicode math into LaTeX segments wrapped in
// $...$ so SolutionRichText (flutter_math_fork Math.tex) typesets it.
//
// Pure Dart: no Flutter import, so it is unit-testable without a
// widget binding and reusable anywhere plain text becomes math.
//
// Conservative by design, per the approved plan:
//  * Bangla script, Bangla digits, dates and prose are never altered.
//  * Existing $...$ segments pass through untouched.
//  * A fraction a/b becomes \frac{a}{b} only in clear math context;
//    date-like chains (10/02/2024), Bangla-digit fractions and slashes
//    between prose words stay inline.
//  * Set-builder braces become \left\{...\right\} only when the brace
//    group contains no Bangla script; otherwise the braces stay literal
//    and only the pure-symbol runs inside are converted.
//  * No bare '|' is ever emitted inside $...$: absolute value uses
//    \left|...\right|, a separator bar uses \mid.
//  * Unparseable input is returned unwrapped, never crashed on and
//    never dropped. Empty input returns empty output.

/// Converts plain text [input] into the same text with converted math
/// runs wrapped in `$...$` segments. Existing `$...$` segments are
/// preserved verbatim.
String normalizeMathText(String input) {
  if (input.isEmpty) return '';
  final out = StringBuffer();
  // Split on existing $...$ segments first; never re-process inside.
  final dollar = RegExp(r'\$[^$]*\$');
  var cursor = 0;
  for (final m in dollar.allMatches(input)) {
    if (m.start > cursor) {
      out.write(_processPlain(input.substring(cursor, m.start)));
    }
    out.write(m.group(0)); // Existing segment, verbatim.
    cursor = m.end;
  }
  if (cursor < input.length) {
    out.write(_processPlain(input.substring(cursor)));
  }
  return out.toString();
}

// ---------------------------------------------------------------------------
// Plain-chunk processing: split into math runs vs prose.
// ---------------------------------------------------------------------------

String _processPlain(String s) {
  final out = StringBuffer();
  final run = StringBuffer();

  void flushRun() {
    if (run.isEmpty) return;
    final raw = run.toString();
    run.clear();
    var start = 0;
    while (start < raw.length && raw[start] == ' ') {
      start++;
    }
    var end = raw.length;
    while (end > start && raw[end - 1] == ' ') {
      end--;
    }
    final core = raw.substring(start, end);
    if (core.isEmpty) {
      out.write(raw); // Whitespace only: keep it as-is.
      return;
    }
    if (_looksLikeMath(core)) {
      out.write(raw.substring(0, start));
      out.write('\$');
      out.write(_convertMath(core));
      out.write('\$');
      out.write(raw.substring(end));
    } else {
      out.write(raw); // Lone number / word / date: never wrapped.
    }
  }

  var i = 0;
  while (i < s.length) {
    final c = s[i];
    if (c == '{') {
      final close = _matching(s, i, '{', '}');
      if (close == -1) {
        flushRun();
        out.write('{'); // Unmatched brace: literal prose.
        i++;
      } else {
        final inner = s.substring(i + 1, close);
        if (_containsBangla(inner)) {
          // Braces stay literal; only pure-symbol runs inside convert.
          flushRun();
          out.write('{');
          out.write(_processPlain(inner));
          out.write('}');
        } else {
          run.write(s.substring(i, close + 1));
        }
        i = close + 1;
      }
    } else if (_isMathChar(c)) {
      run.write(c);
      i++;
    } else {
      // Bangla script, newlines, quotes, '?' and everything else:
      // terminates a math run and is never altered.
      flushRun();
      out.write(c);
      i++;
    }
  }
  flushRun();
  return out.toString();
}

/// A math run is a maximal span of math characters that contains at least
/// one math operator/symbol. A lone plain number or word is NOT math.
bool _looksLikeMath(String core) {
  const ops = '=<>+-×÷√∈∪∩∖^|π∞≤≥≠±∅θαβΔ';
  for (var i = 0; i < core.length; i++) {
    final c = core[i];
    if (ops.contains(c) || _isSuperOrSub(c)) return true;
  }
  if (core.contains('://') || core.startsWith('www.')) {
    return false; // URL / path: never math.
  }
  // A convertible fraction also qualifies. The fraction matcher itself
  // rejects date chains, so "10/02/2024" stays inline here too.
  return _convertFractions(core) != core;
}

// ---------------------------------------------------------------------------
// Math-run conversion.
// ---------------------------------------------------------------------------

String _convertMath(String core) {
  // Standalone N/Z/Q/R map to \mathbb ONLY in a run containing ∈.
  final setBuilder = core.contains('∈');
  var out = _structural(core);
  out = _superSub(out);
  out = _symbols(out);
  out = _fractions(out);
  if (setBuilder) out = _mathbb(out);
  return out;
}

/// Structural pass: absolute-value bars, brace groups and √ radicands.
/// Inner content is converted recursively, so nested constructs work.
String _structural(String s) {
  final out = StringBuffer();
  var i = 0;
  while (i < s.length) {
    final c = s[i];
    if (c == '|') {
      // Absolute value ONLY with no spaces hugging the bars.
      final close = s.indexOf('|', i + 1);
      if (close != -1 &&
          close > i + 1 &&
          s[i + 1] != ' ' &&
          s[close - 1] != ' ') {
        out.write(r'\left|');
        out.write(_convertMath(s.substring(i + 1, close)));
        out.write(r'\right|');
        i = close + 1;
      } else {
        // Lone / spaced bar = separator, never a bare '|' in $...$.
        out.write(r'\mid');
        i++;
      }
    } else if (c == '{') {
      final close = _matching(s, i, '{', '}');
      if (close == -1) {
        out.write(r'\{');
        i++;
      } else {
        out.write(r'\left\{');
        out.write(_convertMath(s.substring(i + 1, close)));
        out.write(r'\right\}');
        i = close + 1;
      }
    } else if (c == '}') {
      out.write(r'\}'); // Unmatched: escaped, never dropped.
      i++;
    } else if (c == '√') {
      final j = i + 1;
      if (j < s.length && s[j] == '(') {
        final close = _matching(s, j, '(', ')');
        if (close == -1) {
          out.write(c);
          i++;
        } else {
          out.write(r'\sqrt{');
          out.write(_convertMath(s.substring(j + 1, close)));
          out.write('}');
          i = close + 1;
        }
      } else if (j < s.length && _isDigitOrMathLetter(s[j])) {
        var k = j;
        if (_isDigit(s[j])) {
          while (k < s.length && _isDigit(s[k])) {
            k++;
          }
        } else {
          while (k < s.length && _isMathLetter(s[k])) {
            k++;
          }
        }
        out.write(r'\sqrt{');
        out.write(s.substring(j, k));
        out.write('}');
        i = k;
      } else {
        out.write(c); // No radicand: leave, never crash.
        i++;
      }
    } else {
      out.write(c);
      i++;
    }
  }
  return out.toString();
}

const _supMap = {
  '⁰': '0',
  '¹': '1',
  '²': '2',
  '³': '3',
  '⁴': '4',
  '⁵': '5',
  '⁶': '6',
  '⁷': '7',
  '⁸': '8',
  '⁹': '9',
};

const _subMap = {
  '₀': '0',
  '₁': '1',
  '₂': '2',
  '₃': '3',
  '₄': '4',
  '₅': '5',
  '₆': '6',
  '₇': '7',
  '₈': '8',
  '₉': '9',
};

bool _isSuperOrSub(String c) =>
    _supMap.containsKey(c) || _subMap.containsKey(c);

/// Unicode superscripts/subscripts -> ^{n} / _{n}; multi-digit runs
/// group into one brace pair (x¹² -> x^{12}).
String _superSub(String s) {
  final out = StringBuffer();
  var i = 0;
  while (i < s.length) {
    final c = s[i];
    if (_supMap.containsKey(c)) {
      final digits = StringBuffer();
      while (i < s.length && _supMap.containsKey(s[i])) {
        digits.write(_supMap[s[i]]);
        i++;
      }
      out.write('^{${digits.toString()}}');
    } else if (_subMap.containsKey(c)) {
      final digits = StringBuffer();
      while (i < s.length && _subMap.containsKey(s[i])) {
        digits.write(_subMap[s[i]]);
        i++;
      }
      out.write('_{${digits.toString()}}');
    } else {
      out.write(c);
      i++;
    }
  }
  return out.toString();
}

const _symbolMap = {
  '∈': r'\in',
  '∪': r'\cup',
  '∩': r'\cap',
  '∖': r'\setminus',
  'π': r'\pi',
  '∞': r'\infty',
  '≤': r'\leq',
  '≥': r'\geq',
  '≠': r'\neq',
  '±': r'\pm',
  '∅': r'\emptyset',
  '×': r'\times',
  '÷': r'\div',
  'θ': r'\theta',
  'α': r'\alpha',
  'β': r'\beta',
  'Δ': r'\Delta',
};

String _symbols(String s) {
  final out = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final c = s[i];
    final cmd = _symbolMap[c];
    if (cmd == null) {
      out.write(c);
    } else {
      out.write(cmd);
      // A LaTeX command name gobbles a following letter ("\pi" + "x"
      // would parse as "\pix"), so separate it with a space, which
      // LaTeX consumes as the command terminator.
      if (i + 1 < s.length && _isAsciiLetter(s[i + 1])) {
        out.write(' ');
      }
    }
  }
  return out.toString();
}

// ---------------------------------------------------------------------------
// Fractions: a/b -> \frac{a}{b} only in clear math context.
// ---------------------------------------------------------------------------

String _fractions(String s) => _convertFractions(s);

String _convertFractions(String s) {
  final out = StringBuffer();
  var copied = 0; // s[0..copied) already written.
  var i = 0;
  while (i < s.length) {
    if (s[i] == '/') {
      final ls = _leftOperandStart(s, i);
      if (ls != -1) {
        final re = _rightOperandEnd(s, i);
        if (re != -1) {
          out.write(s.substring(copied, ls));
          out.write(
            '\\frac{${s.substring(ls, i)}}{${s.substring(i + 1, re)}}',
          );
          i = re;
          copied = re;
          continue;
        }
      }
    }
    i++;
  }
  out.write(s.substring(copied));
  return out.toString();
}

/// Start index of the left operand ending just before [slash], or -1.
/// Operands are Latin letters/digits or parenthesized/brace groups.
/// Rejects date chains (digit or '/' before) and decimals ('.' before).
int _leftOperandStart(String s, int slash) {
  final j = slash - 1;
  if (j < 0) return -1;
  final c = s[j];
  int start;
  if (_isDigit(c) || _isAsciiLetter(c)) {
    var k = j;
    while (k >= 0 && (_isDigit(s[k]) || _isAsciiLetter(s[k]))) {
      k--;
    }
    start = k + 1;
    // A letter run preceded by '\' is a LaTeX command: include it.
    if (start - 1 >= 0 && s[start - 1] == '\\') {
      start = start - 1;
    }
  } else if (c == ')') {
    final open = _matchingBack(s, j, ')', '(');
    if (open == -1) return -1;
    start = open;
    // Function name before the parens, e.g. f(x).
    var k = open - 1;
    while (k >= 0 && _isAsciiLetter(s[k])) {
      k--;
    }
    start = k + 1;
  } else if (c == '}') {
    final open = _matchingBack(s, j, '}', '{');
    if (open == -1) return -1;
    if (open - 1 >= 0 && (s[open - 1] == '^' || s[open - 1] == '_')) {
      // Base^{...} / base_{...}: include the base too.
      final b = open - 2;
      if (b >= 0 && (_isDigit(s[b]) || _isAsciiLetter(s[b]))) {
        var k = b;
        while (k >= 0 && (_isDigit(s[k]) || _isAsciiLetter(s[k]))) {
          k--;
        }
        start = k + 1;
      } else if (b >= 0 && s[b] == ')') {
        final open2 = _matchingBack(s, b, ')', '(');
        if (open2 == -1) return -1;
        start = open2;
        var k = open2 - 1;
        while (k >= 0 && _isAsciiLetter(s[k])) {
          k--;
        }
        start = k + 1;
      } else {
        start = open;
      }
    } else if (open - 1 >= 0 && _isAsciiLetter(s[open - 1])) {
      // Command with braces, e.g. \sqrt{17}.
      var k = open - 1;
      while (k >= 0 && _isAsciiLetter(s[k])) {
        k--;
      }
      start = (k >= 0 && s[k] == '\\') ? k : open;
    } else {
      start = open;
    }
  } else {
    return -1;
  }
  if (start - 1 >= 0) {
    final p = s[start - 1];
    if (_isDigit(p) || p == '/' || p == '.') return -1;
  }
  return start;
}

/// End-exclusive index of the right operand starting just after [slash],
/// or -1. Rejects date chains (digit or '/' after) and decimals.
int _rightOperandEnd(String s, int slash) {
  final k = slash + 1;
  if (k >= s.length) return -1;
  final c = s[k];
  int end;
  if (c == '\\') {
    var e = k + 1;
    while (e < s.length && _isAsciiLetter(s[e])) {
      e++;
    }
    if (e == k + 1) return -1; // Lone backslash.
    if (e < s.length && s[e] == '{') {
      final close = _matching(s, e, '{', '}');
      if (close == -1) return -1;
      end = close + 1;
    } else {
      end = e;
    }
  } else if (_isDigit(c) || _isAsciiLetter(c)) {
    var e = k;
    while (e < s.length && (_isDigit(s[e]) || _isAsciiLetter(s[e]))) {
      e++;
    }
    end = e;
  } else if (c == '(') {
    final close = _matching(s, k, '(', ')');
    if (close == -1) return -1;
    end = close + 1;
  } else if (c == '{') {
    final close = _matching(s, k, '{', '}');
    if (close == -1) return -1;
    end = close + 1;
  } else {
    return -1;
  }
  if (end < s.length) {
    final n = s[end];
    if (_isDigit(n) || n == '/' || n == '.') return -1;
  }
  // Prose-word guard: "and/or", "for/example" must not become a
  // fraction. Both sides pure letters, left word-length >= 3, means
  // prose, not math (school math uses 1-2 letter variables here).
  final left = s.substring(_leftOperandStart(s, slash), slash);
  final right = s.substring(k, end);
  if (_isPureLetters(left) &&
      _isPureLetters(right) &&
      left.length >= 3 &&
      right.length >= 2) {
    return -1;
  }
  return end;
}

bool _isPureLetters(String s) {
  if (s.isEmpty) return false;
  for (var i = 0; i < s.length; i++) {
    if (!_isAsciiLetter(s[i])) return false;
  }
  return true;
}

// ---------------------------------------------------------------------------
// \mathbb mapping (set-builder runs only; caller checks for ∈).
// ---------------------------------------------------------------------------

String _mathbb(String s) {
  final out = StringBuffer();
  var i = 0;
  while (i < s.length) {
    if (s.startsWith(r'\mathbb{', i)) {
      // Already converted: skip the whole span, never double-wrap.
      final close = _matching(s, i + 7, '{', '}');
      if (close == -1) {
        out.write(s[i]);
        i++;
      } else {
        out.write(s.substring(i, close + 1));
        i = close + 1;
      }
      continue;
    }
    final c = s[i];
    if ((c == 'N' || c == 'Z' || c == 'Q' || c == 'R') &&
        (i == 0 || !_isAlnum(s[i - 1])) &&
        (i + 1 >= s.length || !_isAlnum(s[i + 1]))) {
      out.write('\\mathbb{$c}');
    } else {
      out.write(c);
    }
    i++;
  }
  return out.toString();
}

// ---------------------------------------------------------------------------
// Character classes and matching helpers.
// ---------------------------------------------------------------------------

bool _isDigit(String c) {
  final code = c.codeUnitAt(0);
  return code >= 0x30 && code <= 0x39;
}

bool _isAsciiLetter(String c) {
  final code = c.codeUnitAt(0);
  return (code >= 0x41 && code <= 0x5A) ||
      (code >= 0x61 && code <= 0x7A);
}

bool _isAlnum(String c) => _isDigit(c) || _isAsciiLetter(c);

bool _isMathLetter(String c) {
  final code = c.codeUnitAt(0);
  return _isAsciiLetter(c) ||
      (code >= 0x0370 && code <= 0x03FF) || // Greek
      (code >= 0x1F00 && code <= 0x1FFF); // Greek extended
}

bool _isDigitOrMathLetter(String c) => _isDigit(c) || _isMathLetter(c);

/// Latin/Greek letters, digits, operators, set symbols, superscripts,
/// parens/brackets/braces and the punctuation that joins math tokens.
/// Bangla script (U+0980–U+09FF, danda U+0964–U+0965) is NOT in this set,
/// so it always terminates a math run.
bool _isMathChar(String c) {
  if (_isDigitOrMathLetter(c)) return true;
  if (_isSuperOrSub(c)) return true;
  // Operator / set symbols (outside the Greek block).
  if ('∈∪∩∖∞≤≥≠±∅×÷√'.contains(c)) return true;
  return '()[]{}^_/.,:;|!%+<>=*-\''.contains(c) || c == ' ';
}

/// Index of the [closeCh] matching the opener at [open], or -1.
int _matching(String s, int open, String openCh, String closeCh) {
  var depth = 0;
  for (var i = open; i < s.length; i++) {
    if (s[i] == openCh) depth++;
    if (s[i] == closeCh) {
      depth--;
      if (depth == 0) return i;
    }
  }
  return -1;
}

/// Index of the [openCh] matching the closer at [close], or -1.
int _matchingBack(String s, int close, String closeCh, String openCh) {
  var depth = 0;
  for (var i = close; i >= 0; i--) {
    if (s[i] == closeCh) depth++;
    if (s[i] == openCh) {
      depth--;
      if (depth == 0) return i;
    }
  }
  return -1;
}

bool _containsBangla(String s) {
  for (var i = 0; i < s.length; i++) {
    final code = s.codeUnitAt(i);
    if ((code >= 0x0980 && code <= 0x09FF) ||
        (code >= 0x0964 && code <= 0x0965)) {
      return true;
    }
  }
  return false;
}
