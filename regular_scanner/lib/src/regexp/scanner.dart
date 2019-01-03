import 'package:charcode/ascii.dart';
import 'package:meta/meta.dart' show alwaysThrows;

import '../../built_scanner.dart';
import '../range.dart';

part 'scanner.g.dart';

const controlCharacterEscapeTranslations = {
  $t: $tab,
  $r: $cr,
  $n: $lf,
  $v: $vt,
  $f: $ff,
  $0: $nul
};

//
// Shared patterns
//

const _controlCharacterEscape =
    TokenType(r'\\[trnvf0]', _extractConrolCharacter);
const _unicodeEscape =
    TokenType(r'\\[Uu]{[0-9A-Fa-f]+}', _extractUnicodeCodePoint);
const _sharedContextEscapes = TokenType(r'\\[\[\]\\]', _extractAsciiCharacter);
const characterSetStart = TokenType(r'\[');
const characterSetEnd = TokenType(r'\]');

//
// default context patterns
//

const _defaultContextEscapes =
    TokenType(r'\\[.+*?()|]', _extractAsciiCharacter);
const dot = TokenType(r'\.');
const repetition = TokenType(r'[+*?]');
const groupStart = TokenType(r'\(');
const groupEnd = TokenType(r'\)');
const choice = TokenType(r'\|');
const characterSetAlias = TokenType(r'\\[dwsDWS]');

//
// character set patterns
//

const _characterSetEscapes = TokenType(r'\\[\^\-]', _extractAsciiCharacter);
const rangeSeparator = TokenType(r'-');
const negation = TokenType(r'^');

/// Indicates that the current character should be treated as a literal.
///
/// The scanners don't actually match against this regex, because literal
/// characters can be made of surrogate pairs that would have be matched as
/// `..` (and we'd have to add even more dots when we add grapheme cluster
/// support). Instead, whenever *none* of the above regexes match, we treat
/// that as a literal.
const literal = TokenType('.');

@InjectScanner([
  _controlCharacterEscape,
  _unicodeEscape,
  _sharedContextEscapes,
  _defaultContextEscapes,
  characterSetStart,
  characterSetEnd,
  dot,
  repetition,
  groupStart,
  groupEnd,
  choice,
  characterSetAlias
])
const Scanner<TokenType> defaultContextScanner = _$defaultContextScanner;

@InjectScanner([
  _controlCharacterEscape,
  _unicodeEscape,
  _sharedContextEscapes,
  _characterSetEscapes,
  characterSetStart,
  characterSetEnd,
  rangeSeparator,
  negation
])
const Scanner<TokenType> characterSetScanner = _$characterSetScanner;

/// Extracts the unicode rune that an escape sequence should match.
typedef ValueExtractor = int Function(ScannerMatch m);

int _extractIdentity(ScannerMatch m) {
  assert(m.length == 1);
  return m.input.codeUnitAt(m.start);
}

int _extractAsciiCharacter(ScannerMatch m) {
  assert(m.length == 2);
  assert(m.input.codeUnitAt(m.start) == $backslash);
  return m.input.codeUnitAt(m.start + 1);
}

int _extractConrolCharacter(ScannerMatch m) {
  assert(m.length == 2);
  assert(m.input.codeUnitAt(m.start) == $backslash);
  return controlCharacterEscapeTranslations[m.input.codeUnitAt(m.start + 1)];
}

int _extractUnicodeCodePoint(ScannerMatch m) {
  assert(m.regex == _unicodeEscape);

  const prefixLength = r'\u{'.length;
  const suffixLength = r'}'.length;

  final hexString =
      m.input.substring(m.start + prefixLength, m.end - suffixLength);
  // Return the integer unchecked. The range check will be done by
  // [codePointToRune].
  return int.parse(hexString, radix: 16);
}

class TokenType extends Regex {
  const TokenType(String regex, [this.extractCodePoint = _extractIdentity])
      : super(regex);

  final ValueExtractor extractCodePoint;
  bool get convertToLiteral => extractCodePoint != _extractIdentity;
}

/// Presents [pattern] as a sequence of regular expression tokens.
///
/// [current] contains the type of the current token, which is one of the top
/// level constants of this library. ([literal], [groupStart], etc.) These are
/// determined by [defaultContextScanner] and [characterSetScanner]; which one
/// is used depends on the value of [insideCharacterSet]. The type is resolved
/// whenever [moveNext] is called, and doesn't change for the current token
/// when [insideCharacterSet] changes.
///
/// Depending on [literalIsSingleCodeUnit], [codeUnit] or [codeUnits] contains
/// the code unit values of the current token. Backslash-escaped characters are
/// recognized as [literal]  tokens, and [codeUnit]/[codeUnits] contain the
/// decoded value.
class TokenIterator implements Iterator<Regex> {
  TokenIterator(this.pattern);

  /// The string that is scanned by this iterator.
  final String pattern;

  /// The current match starts at this code unit in [pattern].
  int _position = 0;

  /// The next time [moveNext] is called, it will start scanning [pattern] at
  /// this position.
  int _nextPosition = 0;

  TokenType _current;
  dynamic /* int|List<int> */ _rune;

  @override
  TokenType get current => _current;

  /// Returns `true` if the current [literal] token is a surrogate pair, and
  /// must be encoded as two subsequent states.
  bool get literalIsSingleCodeUnit => _rune is int;

  int get codeUnit => _rune;
  List<int> get codeUnits => _rune;

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
  /// [FormatException] with [onRegexEnd] as message. Throws a [RangeError] if
  /// an unpaired surrogate is found. In either case, the iterator is
  /// immediately placed behind the last element ([current] is `null` and calls
  /// to [moveNext] return `false`).
  @override
  bool moveNext({String onRegexEnd}) {
    _position = _nextPosition;
    if (_position >= pattern.length) {
      _current = _rune = null;
      if (onRegexEnd != null) error(onRegexEnd, pattern.length - 1);
      return false;
    }

    try {
      final match =
          (insideCharacterSet ? characterSetScanner : defaultContextScanner)
              .matchAsPrefix(pattern, _position);

      if (match != null) {
        if (match.regex.convertToLiteral) {
          // Call `codePointToRune` and `extractCodePoint` first, because they
          // can throw exceptions and would leave this object in an undefined
          // state.
          _rune = codePointToRune(match.regex.extractCodePoint(match));
          _current = literal;
        } else {
          // If [TokenType.convertToLiteral] is false, the pattern matches
          // either a single ASCII character, or `\` followed by a single ASCII
          // character.
          assert(match.length == 1 ||
              match.length == 2 &&
                  pattern.codeUnitAt(match.start) == $backslash);
          _current = match.regex;
          _rune = pattern.codeUnitAt(match.end - 1);
        }
        _nextPosition = match.end;
      } else if (pattern.codeUnitAt(_position) == $backslash) {
        error('Unrecognized escape sequence');
      } else {
        // The current character is a literal. Use [RuneIterator] to detect
        // surrogate pairs.
        final runes = RuneIterator.at(pattern, _position)..moveNext();
        _current = literal;
        _rune = runes.currentSize == 1
            ? pattern.codeUnitAt(_position)
            : [
                pattern.codeUnitAt(_position),
                pattern.codeUnitAt(_position + 1)
              ];
        _nextPosition += runes.currentSize;
      }
      _position = _position;
      return true;
    } catch (_) {
      _position = _nextPosition = pattern.length;
      _current = _rune = null;
      rethrow;
    }
  }

  /// Convenience method to throw a [FormatException] with [message] and
  /// [offset]. Uses [index] if [offset] is omitted.
  @alwaysThrows
  void error(String message, [int offset]) =>
      throw FormatException(message, pattern, offset ?? index);
}

/// Returns [codePoint] as an [int] if it fits in a single code unit, or as a
/// `List<int>` containing the two surrogate halves, otherwise.
///
/// Algorithm copied from: https://www.unicode.org/faq/utf_bom.html#utf16-4
dynamic /* int|List<int> */ codePointToRune(int codePoint) {
  const unicodeRange = Range(0, 0x10FFFF);
  const surrogateRange = Range(0xD800, 0xDFFF);
  if (!unicodeRange.contains(codePoint) || surrogateRange.contains(codePoint)) {
    throw RangeError.value(
        codePoint, 'codePoint', 'Not a valid Unicode code point');
  }

  if (codePoint <= 0xFFFF) {
    return codePoint;
  }

  const _leadOffset = 0xD800 - (0x10000 >> 10);

  final lead = _leadOffset + (codePoint >> 10);
  final trail = 0xDC00 + (codePoint & 0x3FF);
  return [lead, trail];
}
