/// An NFA is referenced as an iterable of start [NState]s.
library state_machines;

import 'src/state_machine/nfa.dart';

class MatchResult<T> {
  MatchResult(this.accept, this.input, this.start, this.end);

  final Iterable<int> input;
  final int start;
  final int end;
  final T accept;
}

/* class MultimatchResult<T> {} */

abstract class StateMachine<T> {
  /// Finds the longest match of this against [sequence] at position [start].
  MatchResult<T> matchAsPrefix(Iterable<int> sequence, [int start = 0]);

  /// Lazily finds all matches that can of this against [sequence] at position
  /// [start].
  Iterable<MatchResult<T>> matchesAt(Iterable<int> sequence, int start);
}
