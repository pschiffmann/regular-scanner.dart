import 'package:regular_scanner/regular_scanner.dart';
import 'package:test/test.dart';

void main() {
  group('Scanner', () {
    group('.matchAsPrefix()', () {
      test('returns `null` if no regex matches', () {
        final scanner = Scanner.unambiguous([Regex('abc')]);
        final match = scanner.matchAsPrefix('xyz');
        expect(match, isNull);
      });

      test('matches optional regexes', () {
        const regex = Regex('a?');
        final scanner = Scanner.unambiguous([regex]);

        final emptyInput = scanner.matchAsPrefix('');
        expect(emptyInput.regex, regex);
        expect(emptyInput.start, 0);
        expect(emptyInput.end, 0);

        final nonMatchingInput = scanner.matchAsPrefix('b');
        expect(nonMatchingInput.regex, regex);
        expect(emptyInput.start, 0);
        expect(emptyInput.end, 0);
      });

      test('is greedy (returns the longest match)', () {
        final short = Regex('a');
        final long = Regex('aa');
        final scanner = Scanner.unambiguous([short, long]);
        final match = scanner.matchAsPrefix('aaa');
        expect(match.regex, long);
        expect(match.start, 0);
        expect(match.end, 2);
      });
    });

    test('.allMatches() finds all non-overlapping matches', () {
      final p1 = Regex('aa');
      final p2 = Regex('a');
      final p3 = Regex('bb');
      final scanner = Scanner.unambiguous([p1, p2, p3]);
      final matches = scanner.allMatches('aa aaabbbaaaa').toList();
      expect(matches.length, 6);
      expect(matches[0].regex, p1);
      expect(matches[0].start, 0);
      expect(matches[0].end, 2);

      expect(matches[1].regex, p1);
      expect(matches[1].start, 3);
      expect(matches[1].end, 5);

      expect(matches[2].regex, p2);
      expect(matches[2].start, 5);
      expect(matches[2].end, 6);

      expect(matches[3].regex, p3);
      expect(matches[3].start, 6);
      expect(matches[3].end, 8);

      expect(matches[4].regex, p1);
      expect(matches[4].start, 9);
      expect(matches[4].end, 11);

      expect(matches[5].regex, p1);
      expect(matches[5].start, 11);
      expect(matches[5].end, 13);
    });
  });
}
