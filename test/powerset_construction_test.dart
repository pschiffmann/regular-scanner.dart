import 'dart:collection';
import 'dart:core' hide Pattern;

import 'package:charcode/ascii.dart';
import 'package:regular_scanner/regular_scanner.dart' hide State;
import 'package:regular_scanner/src/ast.dart' as nfa show State;
import 'package:regular_scanner/src/dfa.dart' as dfa;
import 'package:regular_scanner/src/parser.dart';
import 'package:regular_scanner/src/powerset_construction.dart';
import 'package:regular_scanner/src/ranges.dart';
import 'package:test/test.dart';

final Matcher throwsAssertionError =
    throwsA(const TypeMatcher<AssertionError>());

void main() {
  //State state;
  //setUp(() => state = new Literal(65));

  group('constructDfa', () {
    test('', () {});
  });

  group('constructState', () {
    final stateIds = new LinkedHashMap<List<nfa.State>, int>(
        equals: closureEquality.equals, hashCode: closureEquality.hash);

    int lookupId(List<nfa.State> closure) => closure.isEmpty
        ? dfa.State.errorId
        : stateIds.putIfAbsent(closure, () => stateIds.length);
    List<nfa.State> lookupClosure(int id) =>
        stateIds.entries.firstWhere((entry) => entry.value == id).key;

    setUp(stateIds.clear);

    test('correctly places literals in the transitions list', () {
      final states =
          parse(const Pattern(r'(aa)+|(aaa)+|(ad?)*z')).leafs.toList();

      // position in patterns:
      //   (aa)+|(aaa)+|(ad?)*z
      //    ^     ^      ^
      // expected successors:
      //   (aa)+|(aaa)+|(ad?)*z
      //     ^     ^     ^^   ^
      final result =
          constructState([states[0], states[2], states[5]], lookupId);
      expect(result.transitions.length, 3);
      expect(result.transitions[0], const Range.single($a));
      expect(lookupClosure(result.transitions[0].successor),
          [states[1], states[3], states[5]]);
      expect(result.transitions[1], const Range.single($d));
      expect(lookupClosure(result.transitions[1].successor), [states[6]]);
      expect(result.transitions[2], const Range.single($z));
      expect(lookupClosure(result.transitions[2].successor), [states[7]]);
    });

    test('correctly places character sets in the transitions list', () {
      final states = parse(const Pattern(r'a[a-d]?[c-f]+')).leafs.toList();

      //   a[a-d]?[c-f]+
      //   ^
      final result = constructState([states[0]], lookupId);
      expect(result.transitions.length, 3);
      // [a-b] -> [[a-d]]
      expect(result.transitions[0], const Range($a, $b));
      expect(lookupClosure(result.transitions[0].successor), [states[1]]);
      // [c-d] -> [[a-d], [b-f]]
      expect(result.transitions[1], const Range($c, $d));
      expect(lookupClosure(result.transitions[1].successor),
          [states[1], states[2]]);
      // [e-f] -> [[b-f]]
      expect(result.transitions[2], const Range($e, $f));
      expect(lookupClosure(result.transitions[2].successor), [states[2]]);
    });

    test(
        'adds negated character sets to non-intersecting ranges '
        'in the transitions list', () {
      final states =
          parse(const Pattern(r'a([a-f]+|[^d-p]|k|z)')).leafs.toList();

      final result = constructState([states[0]], lookupId);
      expect(result.transitions.length, 4);

      // [a-c] -> [[a-f], [^d-p]]
      expect(result.transitions[0], const Range($a, $c));
      expect(lookupClosure(result.transitions[0].successor),
          [states[0], states[1]]);
      // [d-f] -> [[a-f]]
      expect(result.transitions[1], const Range($d, $f));
      expect(lookupClosure(result.transitions[1].successor), [states[0]]);
      // [k] -> [[k]]
      expect(result.transitions[2], const Range.single($k));
      expect(lookupClosure(result.transitions[2].successor), [states[2]]);
      // [z] -> [[^d-p], [z]]
      expect(result.transitions[3], const Range.single($z));
      expect(lookupClosure(result.transitions[3].successor),
          [states[1], states[3]]);
    });

    test('correctly merges literals, normal and negated character sets', () {});

    test(
        'composes the default transition state of dot '
        'and negated character set states',
        () {});

    test('resolves the accepting pattern if one exists', () {});

    test('resolves the accepting pattern to `null` if none exists', () {});
  });

  group('highestPrecedencePattern', () {
    test('returns `null` for empty lists', () {
      expect(highestPrecedencePattern([]), isNull);
    });

    test('returns the highest precedence pattern if only one exists', () {
      final expected = const Pattern('a', precedence: 3);
      expect(
          highestPrecedencePattern([
            const Pattern('b', precedence: 1),
            expected,
            const Pattern('c', precedence: 1)
          ]),
          expected);
    });

    test('throws if multiple patterns have the same precedence', () {
      expect(
          () => highestPrecedencePattern(
              [const Pattern('a'), const Pattern('b')]),
          throwsA(const TypeMatcher<ConflictingPatternException>()));
    });
  });
}
