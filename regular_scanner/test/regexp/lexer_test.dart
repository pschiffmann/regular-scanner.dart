import 'package:charcode/ascii.dart';
import 'package:regular_scanner/src/regex/lexer.dart';
import 'package:regular_scanner/src/regex/token.dart';
import 'package:test/test.dart';

final commonEscapeSequences = [
  Token(r'\\', literal, $backslash),
  Token(r'\t', literal, $tab),
  Token(r'\r', literal, $cr),
  Token(r'\n', literal, $lf),
  Token(r'\v', literal, $vt),
  Token(r'\f', literal, $ff),
  Token(r'\0', literal, $nul),
  Token(r'\u{41}', literal, $A),
  Token(r'\u{1F600}', literal, 0x1F600)
];

/// Instantiates a [TokenIterator] with all [Token.lexeme]s of [tokens] as input
/// and tests that the iterator recognizes the expected types and code points.
void expectTokens(List<Token> tokens, {bool inCharacterSetContext = false}) {
  final it = TokenIterator(tokens.map((t) => t.lexeme).join(''))
    ..insideCharacterSet = inCharacterSetContext;
  expect(it.current, isNull);
  expect(it.index, isNull);

  var index = 0;
  for (final token in tokens) {
    expect(it.moveNext(), isTrue);
    expect(it.current, token.type);
    expect(it.codePoint, token.codePoint);
    expect(it.index, index);

    index += token.lexeme.length;
  }
  expect(it.moveNext(), isFalse);
  expect(it.current, isNull);
  expect(it.codePoint, isNull);
  expect(it.index, isNull);
}

/// Checks that [TokenIterator.moveNext] throws when parsing every element in
/// [invalidInputs].
void expectThrows(List<String> invalidInputs,
    {bool inCharacterSetContext = false}) {
  for (final input in invalidInputs) {
    final it = TokenIterator(input)..insideCharacterSet = inCharacterSetContext;
    expect(it.moveNext, throwsFormatException);
  }
}

/// Describes as which [type] and [codePoint] the [lexeme] should be recognized
/// by [TokenIterator.moveNext].
class Token {
  Token(this.lexeme, this.type, [int codePoint])
      : codePoint = type == literal ? codePoint ?? lexeme.runes.single : null,
        assert(type == literal || codePoint == null);

  final String lexeme;
  final TokenType type;
  final int codePoint;
}

void main() {
  group('TokenIterator', () {
    test('handles empty string', () {
      final it = TokenIterator('');
      expect(it.moveNext(), isFalse);
      expect(it.current, isNull);
      expect(it.codePoint, isNull);
    });

    group('in default context', () {
      test(
          'recognizes simple characters as literals',
          () => expectTokens([
                Token('a', literal),
                Token('b', literal),
                Token('§', literal),
                Token('𝄞', literal)
              ]));

      test(
          'recognizes character set special characters as literals',
          () => expectTokens([
                Token('^', literal),
                Token('-', literal),
              ]));

      test(
          'recognizes special characters',
          () => expectTokens([
                Token('[', characterSetStart),
                Token(']', characterSetEnd),
                Token('.', dot),
                Token('+', repetitionPlus),
                Token('*', repetitionStar),
                Token('?', repetitionQuestionmark),
                Token('(', groupStart),
                Token(')', groupEnd),
                Token('|', choice)
              ]));

      test(
          'recognizes escaped special characters as literals',
          () => expectTokens([
                Token(r'\[', literal, $lbracket),
                Token(r'\]', literal, $rbracket),
                Token(r'\.', literal, $dot),
                Token(r'\+', literal, $plus),
                Token(r'\*', literal, $asterisk),
                Token(r'\?', literal, $question),
                Token(r'\(', literal, $lparen),
                Token(r'\)', literal, $rparen),
                Token(r'\|', literal, $pipe)
              ]));

      test('recognizes escape sequences as literals',
          () => expectTokens(commonEscapeSequences));

      test(
          'throws on unrecognized escape sequences',
          () => expectThrows([
                r'\a',
                r'\-',
                r'\^',
                r'\🙃',
                r'\',
              ]));
    });

    group('in character set context', () {
      test(
          'recognizes simple characters as literals',
          () => expectTokens([
                Token('X', literal),
                Token('Y', literal),
                Token('=', literal),
                Token('💯', literal)
              ], inCharacterSetContext: true));
      test(
          'recognizes default context special characters as literals',
          () => expectTokens([
                Token('.', literal),
                Token('+', literal),
                Token('*', literal),
                Token('?', literal),
                Token('(', literal),
                Token(')', literal),
                Token('|', literal)
              ], inCharacterSetContext: true));

      test(
          'recognizes special characters',
          () => expectTokens([
                Token('[', characterSetStart),
                Token(']', characterSetEnd),
                Token('^', negation),
                Token('-', rangeSeparator)
              ], inCharacterSetContext: true));

      test(
          'recognizes escaped special characters as literals',
          () => expectTokens([
                Token(r'\[', literal, $lbracket),
                Token(r'\]', literal, $rbracket),
                Token(r'\^', literal, $caret),
                Token(r'\-', literal, $minus)
              ], inCharacterSetContext: true));

      test(
          'recognizes escape sequences as literals',
          () =>
              expectTokens(commonEscapeSequences, inCharacterSetContext: true));

      test(
          'throws on unrecognized escape sequences',
          () => expectThrows([
                r'\a',
                r'\(',
                r'\)',
                r'\.',
                r'\+',
                r'\*',
                r'\?',
                r'\|',
                r'\🙃',
                r'\',
              ], inCharacterSetContext: true));
    });
  });
}
