// ignore_for_file: prefer_const_constructors

import 'package:regular_scanner/src/state_machine/dfa.dart';
import 'package:regular_scanner/src/state_machine/explain_ambiguity.dart';
import 'package:test/test.dart';

final throwsAssertionError = throwsA(const TypeMatcher<AssertionError>());

void main() {
  group('findShortestPath', () {
    test('handles empty `states`', () => expect(findShortestPath([]), []));

    test(
        'throws AssertionError if start and destination are not connected',
        () => expect(
            // Destination is state 4. State 3 has a transition to 4, but is not
            // connected to state 0.
            () => findShortestPath([
                  DState([
                    Transition.single(0, 1),
                    Transition.single(2, 1),
                    Transition.single(5, 1),
                  ], defaultTransition: 3),
                  DState([
                    Transition.single(0, 1),
                    Transition.single(2, 1),
                  ]),
                  DState([
                    Transition.single(4, 4),
                  ]),
                  DState([
                    Transition.single(0, 1),
                    Transition.single(2, 1),
                  ])
                ]),
            throwsAssertionError));

    test('finds a shortest path from start to destination', () {
      final s0 = DState([], defaultTransition: 1);
      final s1 = DState([
        Transition.single(1, 2),
        Transition.single(10, 4),
      ]);
      final s2 = DState([
        Transition.single(2, 2),
        Transition.single(10, 4),
      ]);
      final s3 = DState([
        Transition.single(100, 5),
      ]);
      final s4 = DState([
        Transition.single(6, 3),
        Transition.single(7, 1),
      ]);
      expect(findShortestPath([s0, s1, s2, s3, s4]), [s0, s1, s4, s3]);
    });
  });
}
