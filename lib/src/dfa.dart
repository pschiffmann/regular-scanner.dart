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

  @override
  String toString() => min == max
      ? '${new String.fromCharCode(min)} -> $successor'
      : '[${new String.fromCharCode(min)}-${new String.fromCharCode(max)}] '
      '-> $successor';
}

class SingleGuardTransition extends SingleElementRange implements Transition {
  const SingleGuardTransition(int value, this.successor) : super(value);

  @override
  final int successor;
}
