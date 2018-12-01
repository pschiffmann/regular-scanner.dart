import 'package:charcode/ascii.dart';
import 'package:regular_scanner/src/scanner.dart';
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
  Token(r'\U{41}', literal, $A),
  Token(r'\u{1F600}', literal, '😀'.codeUnits)
];

/// Instantiates a [TokenIterator] with all [Token.lexeme]s of [tokens] as input
/// and tests that that the iterator recognizes the expected types and runes.
void expectTokens(List<Token> tokens) {
  final it = TokenIterator(tokens.map((t) => t.lexeme).join(''));
  expect(it.current, isNull);
  expect(it.index, isNull);

  var index = 0;
  for (final token in tokens) {
    expect(it.moveNext(), isTrue);
    expect(it.current, token.type);
    expect(it.literalIsSingleCodeUnit ? it.codeUnit : it.codeUnits, token.rune);
    expect(it.index, index);

    index += token.lexeme.length;
  }
  expect(it.moveNext(), isFalse);
  expect(it.current, isNull);
  expect(it.index, isNull);
}

/// Describes as which [type] and [rune] the [lexeme] should be recognized by
/// [TokenIterator.moveNext].
class Token {
  Token(this.lexeme, this.type, [dynamic rune])
      : rune = rune ??
            (lexeme.length == 1 ? lexeme.codeUnitAt(0) : lexeme.codeUnits);

  final String lexeme;
  final TokenType type;
  final dynamic /* int|List<int> */ rune;
}

void main() {
  group('TokenIterator', () {
    test('handles empty string', () {
      final it = TokenIterator('');
      expect(it.moveNext(), isFalse);
      expect(it.current, isNull);
    });

    test('becomes exhausted when throwing an exception', () {
      // A list of (explanation/invalid input string/exception type) triples.
      const invalidInputs = [
        [
          'invalid escape sequence',
          r'\~',
          TypeMatcher<FormatException>(),
        ],
        [
          'escape character with no following character',
          r'\',
          TypeMatcher<FormatException>(),
        ],
        [
          'outside unicode code point range',
          r'\u{FFFFFF}',
          TypeMatcher<RangeError>(),
        ]
      ];

      for (final input in invalidInputs) {
        final it = TokenIterator(input[1]);
        expect(it.moveNext, throwsA(input[2]), reason: input[0]);
        expect(it.current, isNull);
        expect(it.index, isNull);
        expect(it.codeUnit, isNull);
        expect(it.moveNext(), isFalse);
      }
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
                Token('+', repetition),
                Token('*', repetition),
                Token('?', repetition),
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

      test('throws on unrecognized escape sequences', () => expectTokens([]));

      test(
          'recognizes character set aliases',
          () => expectTokens([
                Token(r'\d', characterSetAlias, $d),
                Token(r'\w', characterSetAlias, $w),
                Token(r'\s', characterSetAlias, $s),
                Token(r'\D', characterSetAlias, $D),
                Token(r'\W', characterSetAlias, $W),
                Token(r'\S', characterSetAlias, $S)
              ]));
    });
  });

  group('codePointToRune', () {
    test('returns BMP code points unchanged', () {});

    test('splits non-BMP code points into surrogate pairs', () {});

    test('rejects non-code point numbers', () {});
  });
}
