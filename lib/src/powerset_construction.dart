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

part 'closure.dart';
part 'transitions.dart';

///
List<dfa.State<T>> constructDfa<T extends Pattern>(
    final Iterable<nfa.Root> expressions) {
  if (expressions.isEmpty) {
    throw new ArgumentError('patterns must not be empty');
  }

  /// Maps NFA state closures to [dfa.State.id]s.
  final stateIds = new LinkedHashMap<List<nfa.State>, int>(
      equals: closureEquality.equals, hashCode: closureEquality.hash);

  /// All closures from [stateIds] that have not been processed yet.
  final unresolved = new Queue<MapEntry<List<nfa.State>, int>>();

  /// Returns the [dfa.State.id] that belongs to [closure], allocating a new id
  /// if this is the first time [closure] is looked up. Returns
  /// [dfa.State.errorId] if [closure] is empty.
  int lookupId(List<nfa.State> closure) => closure.isEmpty
      ? dfa.State.errorId
      : stateIds.putIfAbsent(closure, () => stateIds.length);

  /// The fully constructed states.
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

/// Constructs an [nfa.State] from [closure]. [lookupId] is used to resolve the
/// ids of successors of this state.
dfa.State constructState(
    List<nfa.State> closure, int Function(List<nfa.State>) lookupId) {
  final transitions = <MutableTransition>[];
  final negated = <nfa.CharacterSet>[];
  final defaultTransition = mutableClosure();
  for (final successor in closure.expand((state) => state.successors).toSet()) {
    if (successor is nfa.Literal) {
      reserveTransition(transitions, new Range.single(successor.rune),
          successor: successor);
    } else if (successor is nfa.CharacterSet) {
      if (!successor.negated) {
        for (final runes in successor.runes) {
          reserveTransition(transitions, runes, successor: successor);
        }
      } else {
        // Reserve space for the area that will *not* have a transition on
        // [successor].
        for (final runes in successor.runes) {
          reserveTransition(transitions, runes);
        }
        // Remember to add [successor] to all transitions *except*
        // `successor.runes` later, but wait until [transitions] doesn't change
        // anymore.
        negated.add(successor);
      }
    } else {
      assert(successor is nfa.Dot);
      defaultTransition.add(successor);
    }
  }

  for (final transition in transitions) {
    transition.closure.addAll(defaultTransition);

    for (final successor in negated) {
      for (final runes in successor.runes) {
        if (!runes.containsRange(transition)) {
          assert(!runes.intersects(transition));
          transition.closure.add(successor);
        }
      }
    }
  }

  return new dfa.State(finalizeTransitions(transitions, lookupId),
      defaultTransition: lookupId(defaultTransition.toList(growable: false)),
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
