import 'package:charcode/ascii.dart';
import 'package:regular_scanner/src/scanner.dart';
import 'package:test/test.dart';

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
  });
}
