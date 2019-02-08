import 'package:regular_scanner/regular_scanner.dart';
import 'package:test/test.dart';

void main() {
  group('TableDrivenScanner.match()', () {
    test('returns `null` if no regex matches', () {
      final scanner = Scanner.deterministic(const [Regex('abc')]);
      final match = scanner.matchAsPrefix('xyz');
      expect(match, isNull);
    });

    test('matches empty regexes', () {
      const regex = Regex('a?');
      final scanner = Scanner.deterministic([regex]);

      final emptyInput = scanner.matchAsPrefix('');
      expect(emptyInput.regex, regex);

      final nonMatchingInput = scanner.matchAsPrefix('b');
      expect(nonMatchingInput.regex, regex);
    });

    test('is greedy (returns the longest match)', () {
      const short = Regex('a');
      const long = Regex('aa');
      final scanner = Scanner.deterministic([short, long]);
      final match = scanner.matchAsPrefix('aaa');
      expect(match.regex, long);
    });
  });
}
