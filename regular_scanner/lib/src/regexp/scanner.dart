import 'package:charcode/ascii.dart';
import 'package:meta/meta.dart' show alwaysThrows;

import '../../built_scanner.dart';
import 'token.dart';
import 'unicode.dart';

part 'scanner.g.dart';

const _controlCharacterEscape =
    TokenType(r'\\[trnvf0]', _extractConrolCharacter);
const _unicodeEscape =
    TokenType(r'\\[Uu]{[0-9A-Fa-f]+}', _extractUnicodeLiteral);
const _unrecognizedEscape = TokenType(r'\\', _rejectUnrecognizedEscape);
const _sharedContextEscapes = TokenType(r'\\[\[\]\\]', _extractEscapedOperator);
const _defaultContextEscapes =
    TokenType(r'\\[.+*?()|]', _extractEscapedOperator);
const _characterSetEscapes = TokenType(r'\\[\^\-]', _extractEscapedOperator);

@InjectScanner([
  characterSetStart,
  characterSetEnd,
  literal,
  dot,
  repetitionPlus,
  repetitionStar,
  repetitionQuestionmark,
  groupStart,
  groupEnd,
  choice,
  _controlCharacterEscape,
  _unicodeEscape,
  _sharedContextEscapes,
  _unrecognizedEscape,
  _defaultContextEscapes
])
const Scanner<TokenType> defaultContextScanner = _$defaultContextScanner;

@InjectScanner([
  characterSetStart,
  characterSetEnd,
  literal,
  rangeSeparator,
  negation,
  _controlCharacterEscape,
  _unicodeEscape,
  _sharedContextEscapes,
  _characterSetEscapes,
  _unrecognizedEscape
])
const Scanner<TokenType> characterSetScanner = _$characterSetScanner;

/// Presents [pattern] as a sequence of regular expression tokens.
///
/// [current] contains the type of the current token, which is one of the top
/// level constants of this library. ([literal], [groupStart], etc.) These are
/// determined by [defaultContextScanner] and [characterSetScanner]; which one
/// is used depends on the value of [insideCharacterSet]. The type is resolved
/// whenever [moveNext] is called, and doesn't change for the current token
/// when [insideCharacterSet] changes.
///
/// [codePoint] contains the code point values of the current token.
/// Backslash-escaped characters are recognized as [literal]  tokens, and
/// [codePoint] contain the decoded value.
class TokenIterator implements Iterator<Regex> {
  TokenIterator(this.pattern);

  /// The string that is scanned by this iterator.
  final String pattern;

  /// The current match starts at this code unit in [pattern].
  int _position = 0;

  /// The next time [moveNext] is called, it will start scanning [pattern] at
  /// this position.
  int _nextPosition = 0;

  @override
  TokenType get current => _current;
  TokenType _current;

  /// If [current] is [literal], contains the unicode code point of the current
  /// token. Else, returns `null`.
  int get codePoint => _codePoint;
  int _codePoint;

  /// The index of the first code unit of the [current] token in [pattern], or
  /// `null` if [current] doesn't point to an element.
  ///
  /// **Caution**: If [current] is a [literal] matched by an escape sequence,
  /// this index will point to the `\` rather than the escaped character.
  int get index => (_position != _nextPosition) ? _position : null;

  /// This flag changes which characters are recognized as [literal]s or special
  /// characters.
  ///
  /// The iterator doesn't manage this flag itself, it has to be set by the
  /// parsing functions.
  bool insideCharacterSet = false;

  /// Reads the next character from [pattern] and updates [current].
  ///
  /// If there is no next character and [onRegexEnd] is not `null`, throws a
  /// [FormatException] with [onRegexEnd] as message. Throws a [FormatException]
  /// if an unpaired surrogate is found. In either case, the iterator is
  /// immediately placed behind the last element ([current] is `null` and calls
  /// to [moveNext] return `false`).
  @override
  bool moveNext({String onRegexEnd}) {
    _position = _nextPosition;
    if (_position >= pattern.length) {
      _current = _codePoint = null;
      if (onRegexEnd != null) error(onRegexEnd, pattern.length - 1);
      return false;
    }

    try {
      final match =
          (insideCharacterSet ? characterSetScanner : defaultContextScanner)
              .matchAsPrefix(pattern, _position);
      if (match == null) error('Unmatched surrogate half');
      if (match.regex.extractCodePoint != null) {
        _current = literal;
        _codePoint = match.regex.extractCodePoint(match);
      } else {
        _current = match.regex;
        _codePoint = null;
      }
      _nextPosition = match.end;
      return true;
    } catch (_) {
      _position = _nextPosition = pattern.length;
      _current = _codePoint = null;
      rethrow;
    }
  }

  /// Convenience method to throw a [FormatException] with [message] and
  /// [offset]. Uses [index] if [offset] is omitted.
  @alwaysThrows
  void error(String message, [int offset]) =>
      throw FormatException(message, pattern, offset ?? index);
}

/// Extractor for [_controlCharacterEscape].
int _extractConrolCharacter(ScannerMatch m) {
  switch (m.input.codeUnitAt(m.start + 1)) {
    case $t:
      return $tab;
    case $r:
      return $cr;
    case $n:
      return $lf;
    case $v:
      return $vt;
    case $f:
      return $ff;
    case $0:
      return $nul;
    default:
      throw UnimplementedError();
  }
}

/// Extractor for [_unicodeEscape].
int _extractUnicodeLiteral(ScannerMatch m) {
  const prefixLength = r'\u{'.length;
  const suffixLength = r'}'.length;

  final hexString =
      m.input.substring(m.start + prefixLength, m.end - suffixLength);
  final codePoint = int.parse(hexString, radix: 16);
  if (!isValidCodePoint(codePoint)) {
    throw FormatException(
        'Not a Unicode code point', m.input, m.start + prefixLength);
  }
  return codePoint;
}

/// Extractor for [_unrecognizedEscape]. Throws [FormatException].
int _rejectUnrecognizedEscape(ScannerMatch m) =>
    throw FormatException('Unrecognized escape sequence', m.input, m.start);

int _extractEscapedOperator(ScannerMatch m) {
  assert(m.length == 2);
  assert(m.input.codeUnitAt(m.start) == $backslash);
  return m.input.codeUnitAt(m.start + 1);
}
