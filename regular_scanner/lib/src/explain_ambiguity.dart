library regular_scanner.explain_ambiguity;

import 'package:collection/collection.dart';

import 'dfa.dart';

/// Finds a shortest path in [states] from [State.startId] to [destination]
/// using Dijkstras algorithm.
List<State> findAmbiguousInput(List<State> states, int destination) {
  const uninitialized = -1;

  // Maps state id to predecessor state id.
  final predecessors = List<int>.filled(states.length, uninitialized);

  // Maps state id to distance to the start state.
  final distances = List<int>.filled(states.length, uninitialized)
    ..[State.startId] = 0;

  final queue = PriorityQueue<int>(
      (state1, state2) => distances[state1] - distances[state2])
    ..add(State.startId);

  /// If [predecessor] is on a shorter path to the start state, update [state].
  void updateDistance(int state, int predecessor) {
    if (distances[state] != uninitialized &&
        distances[state] <= distances[predecessor] + 1) return;
    predecessors[state] = predecessor;
    distances[state] = distances[predecessor] + 1;
    queue
      ..remove(state)
      ..add(state);
  }

  while (queue.isNotEmpty) {
    final current = queue.removeFirst();
    if (current == destination) {
      break;
    }
    for (final transition in states[current].transitions) {
      updateDistance(transition.successor, current);
    }
    if (states[current].defaultTransition != State.errorId) {
      updateDistance(states[current].defaultTransition, current);
    }
  }
  assert(distances[destination] != uninitialized,
      'States ${State.startId} and $destination are not connected');

  final result = <State>[];
  for (var current = destination;
      current != null;
      current = predecessors[current]) {
    result.insert(0, states[current]);
  }
  return result;
}
