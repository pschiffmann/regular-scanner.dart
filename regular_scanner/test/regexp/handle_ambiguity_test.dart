import 'package:charcode/ascii.dart';
import 'package:regular_scanner/regular_scanner.dart';
import 'package:regular_scanner/src/range.dart';
import 'package:regular_scanner/src/regex/handle_ambiguity.dart';
import 'package:regular_scanner/state_machine.dart';
import 'package:test/test.dart';

void main() {
  group('highestPrecedenceRegex()', () {
    test('returns `null` for empty sets',
        () => expect(highestPrecedenceRegex(<Regex>{}), isNull));

    test('returns the regex with the highest precedence', () {
      final best = Regex('a', precedence: 3);
      expect(
          highestPrecedenceRegex({
            Regex('[a]', precedence: 1),
            Regex('a+', precedence: 2),
            best,
          }),
          best);
    });

    test(
        'throws `AmbiguousRegexException` if multiple regexes '
        'have the highest precedence', () {
      final r1 = Regex('a', precedence: 2),
          r2 = Regex('[a]', precedence: 1),
          r3 = Regex('a+', precedence: 2);
      try {
        highestPrecedenceRegex({r1, r2, r3});
        fail('AmbiguousRegexException was not thrown');
      } on AmbiguousRegexException catch (e) {
        expect(e.collisions, unorderedEquals([r1, r3]));
      }
    });

    test(
        'does not throw if multiple regexes have the same precedence, '
        'but a single regex with higher precedence exists', () {
      final best = Regex('a', precedence: 3);
      expect(
          highestPrecedenceRegex({
            Regex('[a]', precedence: 1),
            Regex('a+', precedence: 1),
            best,
          }),
          best);
    });
  });

  group('orderByPrecedence()', () {
    test('returns `null` for empty sets',
        () => expect(orderByPrecedence(<Regex>{}), isNull));

    test('returns  all values ordered by precedence', () {
      final r1 = Regex('a', precedence: 3),
          r2 = Regex('[a]', precedence: 1),
          r3 = Regex('a+', precedence: 2),
          r4 = Regex('ab?', precedence: 5),
          r5 = Regex('.', precedence: 4);
      expect(orderByPrecedence({r1, r2, r3, r4, r5}), [r4, r5, r1, r3, r2]);
    });

    test(
        'throws `AmbiguousRegexException` if multiple regexes '
        'have the same precedence', () {
      final r1 = Regex('a', precedence: 3),
          r2 = Regex('[a]', precedence: 1),
          r3 = Regex('a+', precedence: 2),
          r4 = Regex('ab?', precedence: 2),
          r5 = Regex('.', precedence: 2);
      try {
        orderByPrecedence({r1, r2, r3, r4, r5});
        fail('AmbiguousRegexException was not thrown');
      } on AmbiguousRegexException catch (e) {
        expect(e.collisions, unorderedEquals([r3, r4, r5]));
      }
    });
  });

  group('findTransitionTo()', () {
    test('selects the best character from transitions', () {
      expect(
          findTransitionTo(
              DState([
                Transition($nul, $us, 1),
                Transition.single($space, 3),
                Transition($lbracket, $rbracket, 5),
                Transition.single($y, 3)
              ], defaultTransition: 2),
              3),
          'y');
    });

    test('finds the best character in defaultTransition', () {
      expect(
          findTransitionTo(
              DState([
                Transition($space, $dot, 1),
                Transition($lt, $gt, 3),
                Transition($a, $m, 4)
              ], defaultTransition: 3),
              3),
          '0');
    });
  });

  test(
      'selectBestCharacter() finds the character that is best readable '
      'when printed in an error message', () {
    expect(selectBestCharacter(Range($nul, $del)).key, 'A');
    expect(selectBestCharacter(Range($nul, $us)).key, '␀');
    expect(selectBestCharacter(Range($nul, $at)).key, '0');
    expect(selectBestCharacter(Range($nul, $slash)).key, '!');
    expect(selectBestCharacter(Range($nul, $space)).key, '␣');
    expect(selectBestCharacter(Range(0x80, 0x10000)).key, r'U+0080');
  });
}
