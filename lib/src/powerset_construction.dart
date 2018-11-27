/// This library implements the [powerset construction][1] algorithm to convert
/// an NDA (built of [nfa.State]s) into a DFA (built of [dfa.State]s).
///
/// [1]: https://en.wikipedia.org/wiki/Powerset_construction
library regular_scanner.src.powerset_construction;

import 'dart:collection';

import 'package:collection/collection.dart' hide binarySearch;

import '../regular_scanner.dart' show Regex;
import 'ast.dart' as nfa;
import 'dfa.dart' as dfa;
import 'ranges.dart';

part 'closure.dart';
part 'transitions.dart';

///
List<dfa.State<T>> constructDfa<T extends Regex>(
    final List<nfa.Root> expressions) {
  if (expressions.isEmpty) {
    throw ArgumentError('patterns must not be empty');
  }

  /// Maps NFA state closures to [dfa.State.id]s.
  final stateIds = LinkedHashMap<List<nfa.State>, int>(
      equals: closureEquality.equals, hashCode: closureEquality.hash);

  /// All closures from [stateIds] that have not been processed yet.
  final unresolved = Queue<MapEntry<List<nfa.State>, int>>();

  /// Returns the [dfa.State.id] that belongs to [closure], allocating a new id
  /// if this is the first time [closure] is looked up. Returns
  /// [dfa.State.errorId] if [closure] is empty.
  int lookupId(List<nfa.State> closure) => closure.isEmpty
      ? dfa.State.errorId
      : stateIds.putIfAbsent(closure, () {
          final id = stateIds.length;
          unresolved.add(MapEntry(closure, id));
          return id;
        });

  /// The fully constructed states.
  final states = <dfa.State<T>>[];

  // Initialize [queue] with a start state. Its closure doesn't need to be
  // sorted because it is never looked up again.
  lookupId(expressions.map((root) => NfaStartState(root)).toList());
  while (unresolved.isNotEmpty) {
    final current = unresolved.removeFirst();
    final closure = current.key;
    final id = current.value;

    final state = constructState<T>(closure, lookupId);

    assert(states.length == id);
    states.add(state);
  }

  return states;
}

/// Constructs an [nfa.State] from [closure]. [lookupId] is used to resolve the
/// ids of successors of this state.
dfa.State<T> constructState<T extends Regex>(
    List<nfa.State> closure, int Function(List<nfa.State>) lookupId) {
  final transitions = <ConstructionTransition>[];
  final negated = <nfa.CharacterSet>[];
  final defaultTransition = constructionClosure();
  for (final successor in closure.expand((state) => state.successors).toSet()) {
    if (successor is nfa.Literal) {
      reserveTransition(transitions, Range.single(successor.rune),
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
      if (!successor.runes.any((runes) => runes.intersects(transition))) {
        transition.closure.add(successor);
      }
    }
  }
  defaultTransition.addAll(negated);

  return dfa.State<T>(finalizeTransitions(transitions, lookupId),
      defaultTransition: lookupId(defaultTransition.toList(growable: false)),
      accept: highestPrecedencePattern(closure
          .where((state) => state.accepting)
          .map((state) => state.root.pattern)));
}

/// Returns the element in [patterns] with the highest [Regex.precedence], or
/// `null` if [patterns] is empty. Throws a [ConflictingPatternException] if
/// there is no single highest precedence pattern.
Regex highestPrecedencePattern(Iterable<Regex> patterns) {
  final highestPrecedence = Set<Regex>();
  for (final pattern in patterns) {
    if (highestPrecedence.isEmpty) {
      highestPrecedence.add(pattern);
      continue;
    }
    if (highestPrecedence.first.precedence == pattern.precedence) {
      highestPrecedence.add(pattern);
    } else if (pattern.precedence > highestPrecedence.first.precedence) {
      highestPrecedence
        ..clear()
        ..add(pattern);
    }
  }

  switch (highestPrecedence.length) {
    case 0:
      return null;
    case 1:
      return highestPrecedence.first;
    default:
      throw ConflictingPatternException(highestPrecedence, null);
  }
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
      throw UnsupportedError('Undefined for this mock state');
  @override
  set repetition(nfa.Repetition repetition) =>
      throw UnsupportedError('Undefined for this mock state');
  @override
  nfa.DelegatingExpression get parent =>
      throw UnsupportedError('Undefined for this mock state');
  @override
  bool get optional => throw UnsupportedError('Undefined for this mock state');
  @override
  bool get repeat => throw UnsupportedError('Undefined for this mock state');
  @override
  int get id => throw UnsupportedError('Undefined for this mock state');
}

/// Thrown when multiple [Regex]s in a scanner match the same input and all
/// have the same [Regex.precedence].
class ConflictingPatternException implements Exception {
  ConflictingPatternException(this.patterns, this.input)
      : assert(patterns.isNotEmpty);

  final Set<Regex> patterns;
  final String input;

  @override
  String toString() => "The following patterns match the string '$input': "
      '${patterns.join(", ")}';
}
