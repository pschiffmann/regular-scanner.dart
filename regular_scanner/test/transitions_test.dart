import 'package:mockito/mockito.dart';
import 'package:regular_scanner/src/ast.dart';
import 'package:regular_scanner/src/powerset_construction.dart';
import 'package:regular_scanner/src/ranges.dart';
import 'package:test/test.dart';

class MockState extends Mock implements State {}

void main() {
  final state1 = MockState();
  final state2 = MockState();
  when(state1.id).thenReturn(1);
  when(state2.id).thenReturn(10);

  group('reservereTansition', () {
    test('inserts a single transition if the list is empty', () {
      final transitions = <ConstructionTransition>[];
      reserveTransition(transitions, const Range(12, 42), successor: state1);
      expect(transitions.length, 1);
      expect(transitions.single, const Range(12, 42));
      expect(transitions.single.closure, [state1]);
    });

    test('ignores non-intersecting left transitions', () {
      final transitions = [ConstructionTransition(10, 20)..closure.add(state1)];
      reserveTransition(transitions, const Range(23, 24), successor: state2);
      expect(transitions.length, 2);
      expect(transitions[0], const Range(10, 20));
      expect(transitions[0].closure, [state1]);
      expect(transitions[1], const Range(23, 24));
      expect(transitions[1].closure, [state2]);
    });

    test('ignores non-intersecting right transitions', () {
      final transitions = [ConstructionTransition(10, 20)..closure.add(state1)];
      reserveTransition(transitions, const Range(4, 6), successor: state2);
      expect(transitions.length, 2);
      expect(transitions[0], const Range(4, 6));
      expect(transitions[0].closure, [state2]);
      expect(transitions[1], const Range(10, 20));
      expect(transitions[1].closure, [state1]);
    });

    test('splits the first intersection if it starts left of range', () {
      final transitions = [ConstructionTransition(10, 20)..closure.add(state1)];
      reserveTransition(transitions, const Range(12, 20), successor: state2);
      expect(transitions.length, 2);
      expect(transitions[0], const Range(10, 11));
      expect(transitions[0].closure, [state1]);
      expect(transitions[1], const Range(12, 20));
      expect(transitions[1].closure, [state1, state2]);
    });

    test(
        'inserts a left transition if the first '
        'intersection starts inside range', () {
      final transitions = [ConstructionTransition(10, 20)..closure.add(state1)];
      reserveTransition(transitions, const Range(8, 20), successor: state2);
      expect(transitions.length, 2);
      expect(transitions[0], const Range(8, 9));
      expect(transitions[0].closure, [state2]);
      expect(transitions[1], const Range(10, 20));
      expect(transitions[1].closure, [state1, state2]);
    });

    test('adds `successor` to all transitions contained in `range`', () {
      final transitions = [
        ConstructionTransition(10, 20)..closure.add(state1),
        ConstructionTransition(21, 30)
      ];
      reserveTransition(transitions, const Range(10, 30), successor: state2);
      expect(transitions.length, 2);
      expect(transitions[0].closure, [state1, state2]);
      expect(transitions[1].closure, [state2]);
    });

    test('inserts new transitions to fill in gaps', () {
      final transitions = [
        ConstructionTransition(10, 15)..closure.add(state1),
        ConstructionTransition(20, 25)
      ];
      reserveTransition(transitions, const Range(10, 25), successor: state2);
      expect(transitions.length, 3);
      expect(transitions[0].closure, [state1, state2]);
      expect(transitions[1], const Range(16, 19));
      expect(transitions[1].closure, [state2]);
      expect(transitions[2].closure, [state2]);
    });

    test('splits the last intersection if it ends right of range', () {
      final transitions = [ConstructionTransition(10, 25)..closure.add(state1)];
      reserveTransition(transitions, const Range(10, 20), successor: state2);
      expect(transitions.length, 2);
      expect(transitions[0], const Range(10, 20));
      expect(transitions[0].closure, [state1, state2]);
      expect(transitions[1], const Range(21, 25));
      expect(transitions[1].closure, [state1]);
    });

    test(
        'inserts a right transition if the last intersection ends inside range',
        () {
      final transitions = [ConstructionTransition(10, 20)..closure.add(state1)];
      reserveTransition(transitions, const Range(10, 25), successor: state2);
      expect(transitions.length, 2);
      expect(transitions[0], const Range(10, 20));
      expect(transitions[0].closure, [state1, state2]);
      expect(transitions[1], const Range(21, 25));
      expect(transitions[1].closure, [state2]);
    });

    test('handles all the things above at once (range spans all transitions)',
        () {
      final transitions = [
        ConstructionTransition(10, 15)..closure.add(state1),
        ConstructionTransition(16, 18)..closure.add(state1),
        ConstructionTransition(20, 22)
      ];
      reserveTransition(transitions, const Range(8, 25), successor: state2);
      expect(transitions.length, 6);
      expect(transitions[0], const Range(8, 9));
      expect(transitions[0].closure, [state2]);
      expect(transitions[1], const Range(10, 15));
      expect(transitions[1].closure, [state1, state2]);
      expect(transitions[2], const Range(16, 18));
      expect(transitions[2].closure, [state1, state2]);
      expect(transitions[3], const Range(19, 19));
      expect(transitions[3].closure, [state2]);
      expect(transitions[4], const Range(20, 22));
      expect(transitions[4].closure, [state2]);
      expect(transitions[5], const Range(23, 25));
      expect(transitions[5].closure, [state2]);
    });
  });

  group('splitTransition', () {
    List<ConstructionTransition> transitions;
    setUp(() =>
        transitions = [ConstructionTransition(10, 20)..closure.add(state1)]);

    test('splits at the correct position', () {
      splitTransition(transitions, 0, 15);
      expect(transitions.length, 2);
      expect(transitions[0], const Range(10, 14));
      expect(transitions[1], const Range(15, 20));
    });

    test('copies `closure` into both new transitions', () {
      splitTransition(transitions, 0, 15);
      expect(transitions[0].closure, [state1]);
      expect(transitions[1].closure, [state1]);
      transitions[0].closure.add(state2);
      expect(transitions[0].closure, [state1, state2]);
      expect(transitions[1].closure, [state1]);
    });

    test('throws if it would create an empty range', () {
      expect(() => splitTransition(transitions, 0, 10),
          throwsA(const TypeMatcher<AssertionError>()));
    });
  });

  group('finalizeTransitions', () {
    int lookupId(Iterable<State> states) =>
        states.fold(0, (tmp, state) => tmp + state.id);

    test("doesn't merge non-adjacent transitions", () {
      final result = finalizeTransitions([
        ConstructionTransition(10, 11)..closure.add(state1),
        ConstructionTransition(13, 15)..closure.add(state1)
      ], lookupId);
      expect(result.length, 2);
      expect(result[0].successor, 1);
      expect(result[1].successor, 1);
    });

    test("doesn't merge adjacent transitions with different closure", () {
      final result = finalizeTransitions([
        ConstructionTransition(10, 11)..closure.add(state1),
        ConstructionTransition(12, 15)..closure.addAll([state1, state2])
      ], lookupId);
      expect(result.length, 2);
      expect(result[0].successor, 1);
      expect(result[1].successor, 11);
    });

    test('merges adjacent transitions with same closure', () {
      final result = finalizeTransitions([
        ConstructionTransition(10, 11)..closure.add(state1),
        ConstructionTransition(12, 15)..closure.add(state1)
      ], lookupId);
      expect(result.length, 1);
      expect(result[0], const Range(10, 15));
      expect(result[0].successor, 1);
    });
  });
}
