import 'package:charcode/ascii.dart';
import 'package:regular_scanner/src/parser.dart';
import 'package:test/test.dart';

void main() {
  group('TokenIterator', () {
    test('handles empty string', () {
      final it = TokenIterator('');
      expect(it.moveNext(), isFalse);
      expect(it.current, isNull);
      expect(it.type, isNull);
    });

    group('recognizes token types in', () {
      void checkRecognizedTypes(
          TokenIterator it, Map<String, TokenType> expected) {
        for (final pair in expected.entries) {
          expect(it.moveNext(), isTrue, reason: 'Too few elements in iterator');
          final char = pair.key.codeUnits.single;
          expect(it.current, char,
              reason: 'Wrong code unit: expected $char '
                  '(${String.fromCharCode(char)}), got ${it.current}');
          expect(it.type, pair.value,
              reason: '${String.fromCharCode(it.current)} '
                  'was recognized as ${it.type}, should be ${pair.value}');
        }
        expect(it.moveNext(), isFalse, reason: 'Too many elements in iterator');
      }

      test('normal mode', () {
        final expected = {
          'a': TokenType.literal,
          '.': TokenType.dot,
          '+': TokenType.repetition,
          '*': TokenType.repetition,
          '?': TokenType.repetition,
          '|': TokenType.alternation,
          '(': TokenType.groupStart,
          ')': TokenType.groupEnd,
          '[': TokenType.characterSetStart,
          ']': TokenType.characterSetEnd,
          '-': TokenType.literal,
          '^': TokenType.literal,
        };
        final it = TokenIterator(expected.keys.join());
        checkRecognizedTypes(it, expected);
      });

      test('character set mode', () {
        final expected = {
          'a': TokenType.literal,
          '.': TokenType.literal,
          '+': TokenType.literal,
          '*': TokenType.literal,
          '?': TokenType.literal,
          '|': TokenType.literal,
          '(': TokenType.literal,
          ')': TokenType.literal,
          '[': TokenType.characterSetStart,
          ']': TokenType.characterSetEnd,
          '-': TokenType.rangeSeparator,
          '^': TokenType.setNegation,
        };
        final it = TokenIterator(expected.keys.join())
          ..insideCharacterSet = true;
        checkRecognizedTypes(it, expected);
      });
    });

    group('recognizes escape sequences in', () {
      final namedControlCharacters = {
        r'\t': $ht,
        r'\r': $cr,
        r'\n': $lf,
        r'\v': $vt,
        r'\f': $ff,
        r'\b': $bs,
        r'\0': $nul,
        r'\\': $backslash
      };

      void checkEscapeValues(TokenIterator it, Iterable<int> expected) {
        for (final char in expected) {
          expect(it.moveNext(), isTrue, reason: 'Too few elements in iterator');
          expect(it.type, TokenType.literal,
              reason: '${it.current} was recognized as ${it.type}, '
                  'should be TokenType.literal');
          expect(it.current, char,
              reason: 'Wrong code unit: expected $char, got ${it.current}');
        }
        expect(it.moveNext(), isFalse, reason: 'Too many elements in iterator');
      }

      test('normal mode', () {
        final expected = {
          r'\.': $dot,
          r'\+': $plus,
          r'\*': $asterisk,
          r'\?': $question,
          r'\|': $bar,
          r'\(': $lparen,
          r'\)': $rparen,
          r'\[': $lbracket,
          r'\]': $rbracket
        }..addAll(namedControlCharacters);
        final it = TokenIterator(expected.keys.join());
        checkEscapeValues(it, expected.values);
      });

      test('character set mode', () {
        final expected = {
          r'\[': $lbracket,
          r'\]': $rbracket,
          r'\-': $minus,
          r'\^': $caret
        }..addAll(namedControlCharacters);
        final it = TokenIterator(expected.keys.join())
          ..insideCharacterSet = true;
        checkEscapeValues(it, expected.values);
      });
    });

    group('throws on unrecognized escape sequence in', () {
      final neverEscaped = [
        // literals
        r'\a',
        // unsupported character classes and special characters from JS RegExp
        r'\B', r'\x41', r'\$', r'\{', r'\}'
      ];

      test('normal mode', () {
        final unrecognized = [r'\-', r'\^']..addAll(neverEscaped);
        for (final char in unrecognized) {
          final it = TokenIterator(char);
          expect(it.moveNext, throwsFormatException);
        }
      });

      test('character set mode', () {
        final unrecognized = [r'\.', r'\+', r'\*', r'\?', r'\|', r'\(', r'\)']
          ..addAll(neverEscaped);
        for (final char in unrecognized) {
          final it = TokenIterator(char)..insideCharacterSet = true;
          expect(it.moveNext, throwsFormatException);
        }
      });
    });

    test(r'throws if the last character is `\`', () {
      expect(TokenIterator(r'\').moveNext, throwsFormatException);
      expect((TokenIterator(r'\')..insideCharacterSet = true).moveNext,
          throwsFormatException);
    });
  });
}
