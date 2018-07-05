import 'package:regular_scanner/src/ast.dart';
import 'package:regular_scanner/src/powerset_construction.dart';
import 'package:regular_scanner/src/ranges.dart';
import 'package:test/test.dart';

void main() {
  final state1 = new Literal(65);
  final state2 = new Literal(66);
  // The states are sorted by [ConstructionTransition.closure] by their
  // [State.id]. The only way of assigning ids is to put them in a [Root].
  new Root(new Sequence([state1, state2]), null);

  group('reservereTansition', () {
    test('inserts a single transition if the list is empty', () {
      final transitions = <ConstructionTransition>[];
      reserveTransition(transitions, const Range(12, 42), successor: state1);
      expect(transitions.length, 1);
      expect(transitions.single, const Range(12, 42));
      expect(transitions.single.closure, [state1]);
    });

    test('splits the first intersection if it starts left of range', () {
      final transitions = [
        new ConstructionTransition(10, 20)..closure.add(state1)
      ];
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
      final transitions = [
        new ConstructionTransition(10, 20)..closure.add(state1)
      ];
      reserveTransition(transitions, const Range(8, 20), successor: state2);
      expect(transitions.length, 2);
      expect(transitions[0], const Range(8, 9));
      expect(transitions[0].closure, [state2]);
      expect(transitions[1], const Range(10, 20));
      expect(transitions[1].closure, [state1, state2]);
    });

    test('adds `successor` to all transitions contained in `range`', () {
      final transitions = [
        new ConstructionTransition(10, 20)..closure.add(state1),
        new ConstructionTransition(21, 30)
      ];
      reserveTransition(transitions, const Range(10, 30), successor: state2);
      expect(transitions.length, 2);
      expect(transitions[0].closure, [state1, state2]);
      expect(transitions[1].closure, [state2]);
    });

    test('inserts new transitions to fill in gaps', () {
      final transitions = [
        new ConstructionTransition(10, 15)..closure.add(state1),
        new ConstructionTransition(20, 25)
      ];
      reserveTransition(transitions, const Range(10, 25), successor: state2);
      expect(transitions.length, 3);
      expect(transitions[0].closure, [state1, state2]);
      expect(transitions[1], const Range(16, 19));
      expect(transitions[1].closure, [state2]);
      expect(transitions[2].closure, [state2]);
    });

    test('splits the last intersection if it ends right of range', () {
      final transitions = [
        new ConstructionTransition(10, 25)..closure.add(state1)
      ];
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
      final transitions = [
        new ConstructionTransition(10, 20)..closure.add(state1)
      ];
      reserveTransition(transitions, const Range(10, 25), successor: state2);
      expect(transitions.length, 2);
      expect(transitions[0], const Range(10, 20));
      expect(transitions[0].closure, [state1, state2]);
      expect(transitions[1], const Range(21, 25));
      expect(transitions[1].closure, [state2]);
    });
  });

  group('splitTransition', () {
    List<ConstructionTransition> transitions;
    setUp(() => transitions = [
          new ConstructionTransition(10, 20)..closure.add(state1)
        ]);

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
}
