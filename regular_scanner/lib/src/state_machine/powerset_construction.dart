library regular_scanner.src.powerset_construction;

import 'dart:collection';

import 'package:quiver/core.dart';

import '../range.dart';
import 'dfa.dart';
import 'nfa.dart';

/// Constructs an unambiguous deterministic state machine from a
/// nondeterministic one.
///
/// For any powerset with a non-empty set of [NState.accept] values,
/// [resolveAccept] is called to determine which value is used. The default is
/// to throw a [StateError] when more than one is found.
List<DState<T>> powersetConstruction<T>(List<NState<T>> nfa,
        [T Function(Set<T>) resolveAccept]) =>
    _powersetConstruction<T, T>(
        nfa, resolveAccept ?? (accept) => accept.single);

/// Constructs an ambiguous deterministic state machine from a nondeterministic
/// one.
///
/// For any powerset with a non-empty set of [NState.accept] values, the set is
/// passed to [preprocessAccept] and the result is used as the [DState.accept]
/// in the resolved DFA state. This function can be used to filter out certain
/// values, or to arrange them in a desired order. The default is to return all
/// values in an undefined order.
List<DState<List<T>>> powersetConstructionAmbiguous<T>(List<NState<T>> nfa,
        [List<T> Function(Set<T>) preprocessAccept]) =>
    _powersetConstruction<T, List<T>>(
        nfa, preprocessAccept ?? (accept) => accept.toList());

/// Finds all transitive successors of [nfa], passes their powersets to
/// [constructState], and stores the results in a list at the index of their
/// state id.
List<DState<D>> _powersetConstruction<N, D>(
    List<NState<N>> nfa, D Function(Set<N>) computeAccept) {
  if (nfa.isEmpty) throw ArgumentError('`nfa` must not be empty');

  final states = <DState<D>>[];

  /// For discovered powersets, stores the allocated state id.
  final stateIds = LinkedHashMap<Set<NState<N>>, int>(
      equals: _compareSet, hashCode: _hashSet);

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
  lookupId(Set()..add(NStartState(nfa)));

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
/// [_powersetConstruction].
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
      if (successor.guardType == GuardType.wildcard) continue;
      final guardContained = successor.guardType == GuardType.value
          ? range.contains(successor.guard as int)
          : range.intersects(successor.guard as Range);
      if (guardContained != successor.negated) successorSet.add(successor);
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

bool _compareSet(Set a, Set b) => a.length == b.length && a.containsAll(b);
int _hashSet(Set s) =>
    hashObjects(s.map((e) => e.hashCode).toList(growable: false)..sort());
