library regular_scanner.explain_ambiguity;

import 'package:collection/collection.dart';

import 'dfa.dart';

class AmbiguousInputException<T> implements Exception {
  AmbiguousInputException(this.collisions);

  final Iterable<T> collisions;
  List<DState> path;
  int ambiguousState;
}

/// Finds a shortest path in [states] from [Dfa.startState] to a state with id
/// `states.length` using Dijkstras algorithm.
List<DState> findShortestPath(List<DState> states) {
  if (states.isEmpty) return [];

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

  /// If [predecessor] is on a shorter path to the start state, update [state].
  void updateDistance(int state, int predecessor) {
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

  final result = <DState>[];
  for (var current = predecessors[destination];
      true;
      current = predecessors[current]) {
    result.add(states[current]);
    if (current == Dfa.startState) break;
  }
  return result.reversed.toList();
}
