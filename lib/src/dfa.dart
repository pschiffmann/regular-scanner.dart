import 'dart:core' hide Pattern;

import '../regular_scanner.dart';
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
    return index == errorId ? defaultTransition : transitions[index].successor;
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

class TableDrivenScanner<T extends Pattern> implements Scanner<T> {
  const TableDrivenScanner(this.states);

  final List<State<T>> states;

  @override
  MatchResult<T> match(Iterator<int> characters, {bool rewind: false}) {
    var nextState = State.startId;
    var steps = 0;
    MatchResult<T> result;
    while (nextState != State.errorId) {
      final state = states[nextState];
      if (state.accept != null) {
        result = new MatchResult(state.accept, steps);
      }
      if (characters.current == null) {
        break;
      }
      nextState = state.successorFor(characters.current);
      characters.moveNext();
      steps++;
    }

    if (rewind) {
      final it = characters as BidirectionalIterator;
      final stepsBack = result == null ? steps : steps - result.length;
      for (var i = 0; i < stepsBack; i++) {
        it.movePrevious();
      }
    }
    return result;
  }
}

class SingleGuardTransition extends SingleElementRange implements Transition {
  const SingleGuardTransition(int value, this.successor) : super(value);

  @override
  final int successor;
}
