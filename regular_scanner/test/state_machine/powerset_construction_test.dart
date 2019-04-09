import 'dart:collection';

import 'package:regular_scanner/src/state_machine/powerset_construction.dart';
import 'package:regular_scanner/state_machine.dart';
import 'package:test/test.dart';

void main() {
  // We actually call [constructState] only once, because it is so much work to
  // set up all the mock values. The test cases then only validate the output
  // and the objects passed to the callback functions.
  group('constructState', () {
    // Capture the values passed to [computeAccept], and return a mock value
    // that can only be obtained from this function.
    final acceptValue1 = 'acceptValue1', acceptValue2 = 'acceptValue2';
    final computeAcceptResult = 'computeAcceptResult';

    Set<String> passedToAccept;
    String computeAccept(Set<String> accept) {
      passedToAccept = accept;
      return computeAcceptResult;
    }

    // Create a set of successors with illustrative range intersections.

    // guards          | -5 -4 -3 -2 -1  0  1  2  3  4  5  6  7 | *
    //              ------------------------------------------------
    // enter state   a |  x  x  x  x  x  x  x  x  x  x  x       |
    // on `x`        b |  x                                     |
    //               c |  x  x  x  x  x  x  x  x  x  x  x  x  x | x
    //               d |           x  x  x                      |
    //               e |                             x  x  x  x |
    //               f |  x  x                 x  x  x        x | x
    //               g |  x  x     x  x  x  x  x  x  x  x  x  x | x
    //              ------------------------------------------------
    // powerset ids       2  3  4  5  5  5  6  3  3  7  8  9 10  11
    final a = NState<String>.range([Range(-5, 5)]),
        b = NState<String>.value(-5),
        c = NState<String>.wildcard(),
        d = NState<String>.range([Range(-2, 0)]),
        e = NState<String>.range([Range(4, 7)]),
        f = NState<String>.range([Range(-3, 1), Range(5, 6)], negated: true),
        g = NState<String>.value(-3, negated: true);

    // Define the DState ids by hand according to the table above.
    final powersetIds = LinkedHashMap<Set<NState<String>>, int>(
        equals: compareSet, hashCode: hashSet)
      ..addAll({
        {a, b, c, f, g}: 2,
        {a, c, f, g}: 3,
        {a, c}: 4,
        {a, c, d, g}: 5,
        {a, c, g}: 6,
        {a, c, e, f, g}: 7,
        {a, c, e, g}: 8,
        {c, e, g}: 9,
        {c, e, f, g}: 10,
        {c, f, g}: 11
      });

    int lookupId(Set<NState<String>> powerset) =>
        powersetIds[powerset] ?? fail('Unexpected powerset: $powerset');

    // Create a powerset that has states a-g as successors, and pass it to
    // [constructState].
    final powerset = <NState<String>>{
      NState.value(1, successors: [a, b], accept: acceptValue1),
      NState.value(1, successors: [c, d], accept: acceptValue2),
      NState.range([Range(1, 2)], successors: [e, f, g]),
      NState.wildcard(successors: [b, d], accept: acceptValue1)
    };
    final dstate =
        constructState<String, String>(powerset, lookupId, computeAccept);

    test('uses `computeAccept` to calculate `DState.accept`', () {
      expect(passedToAccept, unorderedEquals([acceptValue1, acceptValue2]));
      expect(dstate.accept, computeAcceptResult);
    });

    test('sorts successors into appropriate buckets', () {
      expect(dstate.transitions, const [
        Transition(-5, -5, 2),
        Transition(-4, -4, 3),
        Transition(-3, -3, 4),
        Transition(-2, 0, 5),
        Transition(1, 1, 6),
        Transition(2, 3, 3),
        Transition(4, 4, 7),
        Transition(5, 5, 8),
        Transition(6, 6, 9),
        Transition(7, 7, 10),
      ]);
    });

    test(
        'includes wildcard and negated successors '
        'in `DState.defaultTransition`',
        () => expect(dstate.defaultTransition, 11));
  });
}
