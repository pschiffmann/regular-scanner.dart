library regular_scanner.src.powerset_construction;

import 'dart:collection';

import 'package:quiver/core.dart';

import '../range.dart';
import 'dfa.dart';
import 'nfa.dart';

/// Finds all transitive successors of [nfa], passes their powersets to
/// [constructState], and stores the results in a list at the index of their
/// state id.
List<DState<D>> powersetConstruction<N, D>(
    List<NState<N>> nfa, D Function(Set<N>) computeAccept) {
  if (nfa.isEmpty) throw ArgumentError('`nfa` must not be empty');

  final states = <DState<D>>[];

  /// For discovered powersets, stores the allocated state id.
  final stateIds =
      LinkedHashMap<Set<NState<N>>, int>(equals: compareSet, hashCode: hashSet);

  /// All powersets from [stateIds] that have not been processed yet.
  final unresolved = Queue<MapEntry<Set<NState<N>>, int>>();

  /// Returns the id of the [DState] that represents [powerset], allocating a
  /// new id if this is the first time [powerset] is looked up. Returns
  /// [Dfa.errorState] if [powerset] is empty.
  int lookupId(Set<NState<N>> powerset) => powerset.isEmpty
      ? Dfa.errorState
      : stateIds.putIfAbsent(powerset, () {
          final id = stateIds.length;
          unresolved.add(MapEntry(powerset, id));
          return id;
        });

  /// Initialize [unresolved].
  lookupId(nfa.toSet());

  while (unresolved.isNotEmpty) {
    final current = unresolved.removeFirst();
    final powerset = current.key;
    final id = current.value;

    final state = constructState<N, D>(powerset, lookupId, computeAccept);

    assert(states.length == id);
    states.add(state);
  }

  return states;
}

/// Constructs a single [DState] from [powerset] for the DFA built in
/// [powersetConstruction].
///
/// [lookupId] maps powersets to state ids in the DFA.
DState<D> constructState<N, D>(Set<NState<N>> powerset,
    int Function(Set<NState<N>>) lookupId, D Function(Set<N>) computeAccept) {
  final successors = powerset.expand((state) => state.successors).toSet();
  final reservedRanges = <Range>[];
  final defaultTransition = Set<NState<N>>();

  // First pass: split [reservedRanges] into ranges, and fill
  // [defaultTransition].
  for (final successor in successors) {
    switch (successor.guardType) {
      case GuardType.value:
        reserve(reservedRanges, Range.single(successor.guard as int));
        if (successor.negated) defaultTransition.add(successor);
        break;
      case GuardType.range:
        reserve(reservedRanges, successor.guard as Range);
        if (successor.negated) defaultTransition.add(successor);
        break;
      case GuardType.wildcard:
        defaultTransition.add(successor);
        break;
    }
  }

  // Second pass: Look up the successor powerset of each [reservedRanges] range.
  final transitions = reservedRanges.map((range) {
    final successorSet = Set<NState<N>>();
    for (final successor in successors) {
      switch (successor.guardType) {
        case GuardType.value:
          final guardContained = range.contains(successor.guard as int);
          if (guardContained != successor.negated) successorSet.add(successor);
          break;
        case GuardType.range:
          final guardContained = range.intersects(successor.guard as Range);
          if (guardContained != successor.negated) successorSet.add(successor);
          break;
        case GuardType.wildcard:
          successorSet.add(successor);
          break;
      }
    }
    return Transition(range.min, range.max, lookupId(successorSet));
  }).toList();

  // Third pass: Merge adjacent transitions if they have the same successor.
  for (var i = 0; i < transitions.length - 1;) {
    final left = transitions[i];
    final right = transitions[i + 1];
    if (left.max + 1 == right.min && left.successor == right.successor) {
      transitions
        ..[i] = Transition(left.min, right.max, left.successor)
        ..removeAt(i + 1);
    } else {
      i++;
    }
  }

  return DState(transitions,
      defaultTransition: lookupId(defaultTransition),
      accept: computeAccept(powerset
          .where((s) => s.accept != null)
          .map((s) => s.accept)
          .toSet()));
}

bool compareSet(Set a, Set b) => a.length == b.length && a.containsAll(b);
int hashSet(Set s) =>
    hashObjects(s.map((e) => e.hashCode).toList(growable: false)..sort());
