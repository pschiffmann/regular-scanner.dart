import 'package:charcode/ascii.dart';
import 'package:regular_scanner/src/scanner.dart';
import 'package:test/test.dart';

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

class Token {
  Token(this.lexeme, this.type, [dynamic rune])
      : rune = rune ??
            (lexeme.length == 1 ? lexeme.codeUnitAt(0) : lexeme.codeUnits);

  final String lexeme;
  final TokenType type;
  final dynamic /* int|List<int> */ rune;
  bool get literalIsSingleCodeUnit => rune is int;
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
        ['invalid escape sequence', r'\~', TypeMatcher<FormatException>()],
        [
          'escape character with no following character',
          r'\',
          TypeMatcher<FormatException>()
        ],
        /* TODO: This test case should work once we generate a new version of
                 [defaultContextScanner].
        [
          'outside unicode code point range',
          r'\u{FFFFFF}',
          TypeMatcher<RangeError>()
        ]*/
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
          'recognizes special characters',
          () => expectTokens([
                Token('(', groupStart),
              ]));

      test(
          'recognizes escaped special characters as literals',
          () => expectTokens([
                Token(r'\(', literal, $lparen),
              ]));

      test('recognizes escape sequences as literals', () => expectTokens([]));

      test('throws on unrecognized escape sequences', () => expectTokens([]));

      test('recognizes character set aliases', () => expectTokens([]));
    });
  });

  group('codePointToRune', () {
    test('returns BMP code points unchanged', () {});

    test('splits non-BMP code points into surrogate pairs', () {});

    test('rejects non-code point numbers', () {});
  });
}
