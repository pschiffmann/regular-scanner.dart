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

    setUp(stateIds.clear);

    /// Checks that [dfa.State.transitions] contains the assigned [transitions],
    /// provided as a mapping from the guard range to the successor closure.
    void checkTransitions(
        dfa.State state, Map<Range, List<nfa.State>> transitions) {
      final actual = state.transitions.iterator;
      final expected = transitions.entries.iterator;
      while (expected.moveNext()) {
        final guard = expected.current.key;
        final closure = expected.current.value;
        expect(actual.moveNext(), isTrue,
            reason: 'state is missing transition $guard -> $closure');
        expect(actual.current, equals(guard));
        final successorId =
            closure.isEmpty ? dfa.State.errorId : stateIds[closure];
        expect(successorId, isNotNull,
            reason:
                "constructDfa didn't allocate a state for closure $closure");
        expect(actual.current.successor, successorId);
      }
      expect(actual.moveNext(), isFalse,
          reason: 'state contains unexpected transition ${actual.current}');
    }

    test('correctly places literals in the transitions list', () {
      final states =
          parse(const Pattern(r'(aa)+|(aaa)+|(ad?)*z')).leafs.toList();

      // position in pattern:
      //   (aa)+|(aaa)+|(ad?)*z
      //    ^     ^      ^
      // expected successors:
      //   (aa)+|(aaa)+|(ad?)*z
      //     ^     ^     ^^   ^
      checkTransitions(
          constructState([states[0], states[2], states[5]], lookupId), {
        const Range.single($a): [states[1], states[3], states[5]],
        const Range.single($d): [states[6]],
        const Range.single($z): [states[7]]
      });
    });

    test('correctly places character sets in the transitions list', () {
      final states = parse(const Pattern(r'a[a-d]?[c-f]+')).leafs.toList();

      //   a[a-d]?[c-f]+
      //   ^
      checkTransitions(constructState([states[0]], lookupId), {
        // [a-b] -> [a-d]
        const Range($a, $b): [states[1]],
        // [c-d] -> [a-d], [b-f]
        const Range($c, $d): [states[1], states[2]],
        // [e-f] -> [b-f]
        const Range($e, $f): [states[2]]
      });
    });

    test(
        'adds negated character sets to non-intersecting ranges '
        'in the transitions list and the default transition', () {
      final states =
          parse(const Pattern(r'a([a-f]+|[^d-p]|k|z)')).leafs.toList();

      final result = constructState([states[0]], lookupId);
      checkTransitions(result, {
        // [a-c] -> [a-f], [^d-p]
        const Range($a, $c): [states[1], states[2]],
        // [d-f] -> [a-f]
        const Range($d, $f): [states[1]],
        // [g-j] -> -1
        const Range($g, $j): const [],
        // [k] -> k
        const Range.single($k): [states[3]],
        // [l-p] -> -1
        const Range($l, $p): const [],
        // [z] -> [^d-p], z
        const Range.single($z): [states[2], states[4]]
      });
      // default -> [^d-p]
      expect(result.defaultTransition, stateIds[[states[2]]]);
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