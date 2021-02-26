import 'package:regular_scanner/regular_scanner.dart';

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
int _extractLiteral(ScannerMatch m) => 0;
