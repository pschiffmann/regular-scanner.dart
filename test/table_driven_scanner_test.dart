import 'dart:core' hide Pattern;

import 'package:charcode/ascii.dart';
import 'package:regular_scanner/regular_scanner.dart';
import 'package:test/test.dart';

void main() {
  group('TableDrivenScanner.match()', () {
    test('returns `null` if no pattern matches', () {
      final scanner = Scanner(const [Pattern('abc')]);
      final match = scanner.match('xyz'.codeUnits.iterator..moveNext());
      expect(match, isNull);
    });

    test('matches empty patterns', () {
      const pattern = Pattern('a?');
      final scanner = Scanner([pattern]);

      final emptyInput = scanner.match(''.codeUnits.iterator..moveNext());
      expect(emptyInput.pattern, pattern);

      final nonMatchingInput =
          scanner.match('b'.codeUnits.iterator..moveNext());
      expect(nonMatchingInput.pattern, pattern);
    });

    test('is greedy (returns the longest match)', () {
      const short = Pattern('a');
      const long = Pattern('aa');
      final scanner = Scanner([short, long]);
      final match = scanner.match('aaa'.codeUnits.iterator..moveNext());
      expect(match.pattern, long);
    });

    test('advances the iterator only while at least one pattern matches', () {
      final scanner = Scanner(const [Pattern('abcde')]);
      final it = 'abcxy'.codeUnits.iterator..moveNext();
      final match = scanner.match(it);
      expect(match, isNull);
      expect(it.current, $x);
    });

    test('places the iterator behind the match if `rewind` is true', () {
      const fours = Pattern('(aaaa)+', precedence: 0);
      const fives = Pattern('(aaaaa)+', precedence: 1);
      final scanner = Scanner([fours, fives]);
      final it = RuneIterator('${"a" * 9}b')..moveNext();
      final match = scanner.match(it, rewind: true);
      expect(match.pattern, fours);
      expect(match.length, 8);
      expect(it.rawIndex, 8);
    });
  });
}
