import 'dart:core' hide Pattern;

import '../regular_scanner.dart' show Pattern;
import 'ranges.dart';

class State<T extends Pattern> {
  const State(this.transitions,
      {this.defaultTransition: State.errorId, this.accept});

  /// The state in `Scanner.states` at index `0` is the start state.
  static const int startId = 0;

  /// [successorFor] returns this value to reject the next character and stop
  /// the match process.
  static const int errorId = -1;

  final List<Transition> transitions;

  /// The transition that should be taken if the read character is not in
  /// [transitions]. This value is never `null` and defaults to [State.errorId].
  final int defaultTransition;

  final T accept;

  int successorFor(int guard) {
    final index = binarySearch(transitions, guard);
    return index == -1 ? defaultTransition : transitions[index];
  }
}

class Transition extends Range {
  const Transition(int min, int max, this.successor) : super(min, max);
  const factory Transition.single(int value, int successor) =
      SingleGuardTransition;

  final int successor;
}

class SingleGuardTransition implements Transition {
  const SingleGuardTransition(this.value, this.successor);

  @override
  final int successor;

  final int value;
  @override
  int get min => value;
  @override
  int get max => value;

  @override
  bool contains(int n) => n == value;

  @override
  String toString() => value.toString();
}
