/// This library implements the [powerset construction][1] algorithm to convert
/// an NDA (built of [nfa.State]s) into a DFA (built of [dfa.State]s).
///
/// [1]: https://en.wikipedia.org/wiki/Powerset_construction
library regular_scanner.src.powerset_construction;

import 'dart:collection';
import 'dart:core' hide Pattern;

import 'package:collection/collection.dart' hide binarySearch;

import '../regular_scanner.dart' show Pattern;
import 'ast.dart' as nfa;
import 'dfa.dart' as dfa;
import 'ranges.dart';

part 'transitions.dart';

///
List<dfa.State<T>> constructDfa<T extends Pattern>(
    final Iterable<nfa.Root> expressions) {
  if (expressions.isEmpty) {
    throw new ArgumentError('patterns must not be empty');
  }

  // Maps DFA state closures to DFA [State.id]s. All keys must be sorted with
  // [_sortClosure] to be comparable by [_closureEquality].
  final stateIds = new LinkedHashMap<List<nfa.State>, int>(
      equals: _closureEquality.equals, hashCode: _closureEquality.hash);

  // All closures from [stateIds] that have not been processed yet.
  final unresolved = new Queue<MapEntry<List<nfa.State>, int>>();

  /// Allocates ascending [nfa.State.id]s, starting from 0 for the start state.
  int lookupId(List<nfa.State> closure) => stateIds.putIfAbsent(closure, () {
        final id = stateIds.length;
        stateIds[closure] = id;
        return id;
      });

  // The fully constructed states.
  final states = <dfa.State>[];

  // Initialize [queue] with a start state. Its closure doesn't need to be
  // sorted because it is never looked up again.
  lookupId(expressions.map((root) => new NfaStartState(root)).toList());
  while (unresolved.isNotEmpty) {
    final closure = unresolved.first.key;
    final id = unresolved.first.value;
    unresolved.removeFirst();

    final state = constructState(closure, lookupId);

    assert(states.length == id);
    states.add(state);
  }

  return states;
}

/// Two closures are considered equal if they contain the same elements. Because
/// [ListEquality] also considers the element order, closures must be sorted
/// with [_sortClosure].
const ListEquality<nfa.State> _closureEquality = const ListEquality();

/// Sorts the states in a closure first by their pattern, then by their id. The
/// order itself doesn't matter, but it needs to be unambiguous so that
/// [_closureEquality] compares and hashes them correctly.
int _sortClosure(nfa.State a, nfa.State b) => a.root != b.root
    ? a.root.pattern.pattern.compareTo(b.root.pattern.pattern)
    : a.id - b.id;

/// Constructs an [nfa.State] from [closure]. [lookupId] is used to resolve the
/// ids of successors of this state.
dfa.State constructState(
    List<nfa.State> closure, int Function(List<nfa.State>) lookupId) {
  final transitions = <MutableTransition>[];
  final negated = <nfa.CharacterSet>[];
  final defaultTransition = <nfa.State>[];
  for (final successor in closure.expand((state) => state.successors.toSet())) {
    if (successor is nfa.Literal) {
      addSuccessor(transitions, successor, new Range.single(successor.rune));
    } else if (successor is nfa.CharacterSet) {
      if (successor.negated) {
        negated.add(successor);
      } else {
        for (final runes in successor.runes) {
          addSuccessor(transitions, successor, runes);
        }
      }
    } else {
      defaultTransition.add(successor as nfa.Dot);
    }
  }

  for (final transition in transitions) {
    transition.closure
      ..addAll(defaultTransition)
      ..sort(_sortClosure);
  }
  defaultTransition.sort(_sortClosure);

  return new dfa.State(
      transitions
          .map((t) => t.min == t.max
              ? new dfa.Transition.single(t.min, lookupId(t.closure))
              : new dfa.Transition(t.min, t.max, lookupId(t.closure)))
          .toList(growable: false),
      defaultTransition: defaultTransition.isEmpty
          ? dfa.State.errorId
          : lookupId(defaultTransition),
      accept: _highestPrecedencePattern(closure.map((state) => state.root)));
}

/// Returns the element in [expressions] with the highest [Pattern.precedence],
/// or `null` if [expressions] is empty. Throws an [Exception] if there is no
/// single highest precedence pattern.
T _highestPrecedencePattern<T extends Pattern>(Iterable<nfa.Root> expressions) {
  T result;
  for (final candidate in expressions.map((root) => root.pattern)) {
    if (result == null) {
      result = candidate;
      continue;
    } else if (result == candidate) {
      continue;
    } else if (result.precedence == candidate.precedence) {
      throw new Exception(
          'Patterns $result and $candidate ambiguously match the same string. '
          'Assign a `Pattern.precedence` to resolve this issue.');
    }
    if (result.precedence == null) {
      result = candidate;
    } else if (candidate.precedence != null &&
        candidate.precedence > result.precedence) {
      result = candidate;
    }
  }
  return result;
}

class NfaStartState implements nfa.State {
  NfaStartState(this.root);

  @override
  final nfa.Root root;

  @override
  Iterable<nfa.State> get successors => root.first;

  @override
  bool get accepting => root.optional;

  @override
  nfa.Repetition get repetition =>
      throw new UnsupportedError('Undefined for this mock state');
  @override
  set repetition(nfa.Repetition repetition) =>
      throw new UnsupportedError('Undefined for this mock state');
  @override
  nfa.DelegatingExpression get parent =>
      throw new UnsupportedError('Undefined for this mock state');
  @override
  Iterable<nfa.State> get leafs =>
      throw new UnsupportedError('Undefined for this mock state');
  @override
  bool get optional =>
      throw new UnsupportedError('Undefined for this mock state');
  @override
  bool get repeat =>
      throw new UnsupportedError('Undefined for this mock state');
  @override
  int get id => throw new UnsupportedError('Undefined for this mock state');
}
