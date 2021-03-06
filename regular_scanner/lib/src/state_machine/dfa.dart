import 'package:collection/collection.dart' show PriorityQueue;
import 'package:quiver/core.dart';

import '../../state_machine.dart';
import '../range.dart';

/// A deterministic finite automaton.
///
/// In general, you shouldn't instantiate this class directly. Instead, define
/// an [Nfa], then convert it to a [Dfa] with [powersetConstruction] or
/// [powersetConstructionAmbiguous].
///
/// The states of a DFA are explicitly listed in [states]. All state
/// transitions are specified as indexes into this list, and must be valid
/// indexes or [errorState]. The state machine starts in [startState].
class Dfa<T> implements StateMachine<T> {
  Dfa(this.states)
      : assert(states.isNotEmpty, 'states must not be empty'),
        _current = startState;

  /// A newly constructed [Dfa] is initially in state 0.
  static const int startState = 0;

  /// When a transition is taken that contains this value, [inErrorState]
  /// becomes `true`.
  static const int errorState = -1;

  final List<DState<T>> states;

  /// Index into [states], or [errorState].
  int _current;

  @override
  bool get inErrorState => _current == errorState;

  @override
  T get accept => inErrorState ? null : states[_current].accept;

  @override
  void moveNext(int input) {
    if (inErrorState) return;
    final state = states[_current];
    final index = binarySearch(state.transitions, input);
    _current = index != errorState
        ? state.transitions[index].successor
        : state.defaultTransition;
  }

  @override
  void reset() => _current = startState;

  @override
  Dfa<T> copy({bool reset = true}) {
    final result = Dfa(states);
    if (!reset) result._current = _current;
    return result;
  }

  /// Finds a shortest path in [states] from [Dfa.startState] to a state with id
  /// `states.length` using Dijkstras algorithm.
  ///
  /// The returned list contains the states on the path, including
  /// [Dfa.startState] and `states.length`. If [states] is empty, returns `[0]`.
  ///
  /// Used by [AmbiguousInputException.toString] to generate ambiguous input
  /// sequences.
  static List<int> findShortestPath(List<DState> states) {
    if (states.isEmpty) return [0];

    const uninitialized = -1;
    final destination = states.length;

    // For each state, stores the immediate predecessor state id.
    final predecessors = List<int>.filled(states.length + 1, uninitialized);

    // For each state, stores the total number of predecessors.
    final distances = List<int>.filled(states.length + 1, uninitialized)
      ..[Dfa.startState] = 0;

    final queue = PriorityQueue<int>((state1, state2) {
      final diff = distances[state1] - distances[state2];
      if (diff != 0) return diff;
      // When two different states have the same distance, we need to return a
      // non-zero value, because [PriorityQueue.remove] uses only the result of
      // this comparison to find the element to remove.
      return state1 - state2;
    });

    /// If [predecessor] is on a shorter path to the start state, update
    /// [state].
    void updateDistance(int state, int predecessor) {
      if (state > destination) {
        // [state] was discovered, but not yet resolved. Trying to access it in
        // [states] or [distances] would yield an [IndexError].
        return;
      }
      if (distances[state] != uninitialized &&
          distances[state] <= distances[predecessor] + 1) return;
      queue.remove(state);
      predecessors[state] = predecessor;
      distances[state] = distances[predecessor] + 1;
      queue.add(state);
    }

    queue.add(Dfa.startState);
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      if (current == destination) break;

      for (final transition in states[current].transitions) {
        updateDistance(transition.successor, current);
      }
      if (states[current].defaultTransition != Dfa.errorState) {
        updateDistance(states[current].defaultTransition, current);
      }
    }
    assert(distances[destination] != uninitialized,
        'States ${Dfa.startState} and $destination are not connected');

    final path = [destination];
    while (true) {
      final predecessor = predecessors[path.last];
      if (predecessor == uninitialized) break;
      path.add(predecessor);
    }
    return path.reversed.toList();
  }
}

/// A single state of [Dfa.states]. If other code refers to the _id_ of a
/// [DState], it means the index in [Dfa.states] at which that state is stored.
class DState<T> {
  const DState(this.transitions,
      {this.defaultTransition = Dfa.errorState, this.accept});

  /// A list of non-intersecting ranges in ascending order.
  final List<Transition> transitions;

  /// The transition that should be taken if the read character is not in
  /// [transitions]. This value is never `null` and defaults to
  /// [Dfa.errorState].
  final int defaultTransition;

  /// If this state is reached, the input matches [accept].
  final T accept;

  @override
  String toString() =>
      'DState(${transitions.join(", ")}' +
      (defaultTransition == Dfa.errorState
          ? ''
          : ', defaultTransition: $defaultTransition') +
      (accept == null ? '' : ', accept: $accept') +
      ')';
}

class Transition extends Range {
  const Transition(int min, int max, this.successor) : super(min, max);
  const Transition.single(int value, this.successor) : super.single(value);

  /// The id of the successor state.
  final int successor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other.runtimeType == Transition &&
          other is Transition &&
          other.min == min &&
          other.max == max &&
          other.successor == successor;

  @override
  int get hashCode => hash3(min, max, successor);

  @override
  String toString() => '${super.toString()} -> $successor';
}
