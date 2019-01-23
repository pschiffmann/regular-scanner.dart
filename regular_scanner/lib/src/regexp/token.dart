import '../../built_scanner.dart';
import 'unicode.dart';

//
// Shared patterns
//

const characterSetStart = TokenType(r'\[');
const characterSetEnd = TokenType(r'\]');
const literal = TokenType('.', _extractLiteral, 0);

//
// default context patterns
//

const dot = TokenType(r'\.');
const repetitionPlus = TokenType(r'\+');
const repetitionStar = TokenType(r'\*');
const repetitionQuestionmark = TokenType(r'\?');
const groupStart = TokenType(r'\(');
const groupEnd = TokenType(r'\)');
const choice = TokenType(r'\|');

//
// character set patterns
//

const rangeSeparator = TokenType(r'-');
const negation = TokenType(r'^');

class TokenType extends Regex {
  const TokenType(String regex, [this.extractCodePoint, int precedence = 1])
      : super(regex, precedence: precedence);

  final int Function(ScannerMatch m) extractCodePoint;
}

/// Extractor for [literal].
int _extractLiteral(ScannerMatch m) {
  assert(m.regex == literal);
  return m.length == 1
      ? m.input.codeUnitAt(m.start)
      : decodeSurrogatePair(
          m.input.codeUnitAt(m.start), m.input.codeUnitAt(m.start + 1));
}
