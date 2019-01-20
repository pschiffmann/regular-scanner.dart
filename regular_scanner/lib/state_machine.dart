/// This library provides access to the state machines that are used under the
/// hood by [StateMachineScanner]. You can use them if you want to implement a
/// state machine-based matching algorithm, but don't want to encode your
/// patterns as regular expressions.
///
/// The interesting member of this library is [powersetConstruction], which
/// creates a deterministic state machine from a nondeterministic one. If you
/// don't need that functionality, you probably don't want to use this library
/// at all, because implementing a state machine isn't very complicated and the
/// API was designed around the primary use case of this package: regular
/// expressions.
///
/// For more information, look at the docs of the individual classes. Start
/// reading at [StateMachine] to learn how a you can use it to match an input.
/// Then, take a look at [Nfa] to learn how to construct your own state machine.
///
/// - explain what it means if an NFA is ambiguous, and that it can't be
///   detected until [powersetConstruction] is called.
/// - NFA start states must never be entered again, because the start *is*
///   already entered without that it's guard is checked for the first input.
///   TODO: Maybe `NState.start` shouldn't be public API, and we should just
///   instantiate some of those internally to have a starting point?
/// - note about naming: guards
library state_machines;

import 'regular_scanner.dart';
import 'src/state_machine/dfa.dart';
import 'src/state_machine/nfa.dart';
import 'src/state_machine/powerset_construction.dart' as impl;

export 'src/range.dart' show Range;
export 'src/state_machine/dfa.dart' show Dfa, DState, Transition;
export 'src/state_machine/nfa.dart' show Nfa, NState;
export 'src/state_machine/powerset_construction.dart' show powersetConstruction;

/// A state machine is a stateful object that processes a single value of an
/// input sequence with each call to [moveNext]. This design allows us to use
/// this class on both [Iterable]s and [Stream]s. The only allowed input is
/// [int]; if you need to match an input sequence of another type, you need to
/// map it to numbers first.
///
/// You can associate states with an object of type [T] to mark that state as an
/// accepting state. When this object currently is in an accepting state, the
/// corresponding object(s) are available through [accept].
///
/// If a state machine reads an input for which the current state has no
/// transition, it reaches an error state. This is observable for callers
/// through [inErrorState]. An error state can't be exited by [moveNext], but
/// the method can still be called.
abstract class StateMachine<T> {
  bool get inErrorState;

  /// If this is in an accepting state, returns the object(s) associated with
  /// these states. Otherwise, returns `null`.
  T get accept;

  /// Takes the transition in the current state guarded by [input], or enters an
  /// error state if no such transition exists.
  void moveNext(int input);

  /// Resets this to be in the start state.
  void reset();

  /// Returns a copy of this.
  ///
  /// If [reset] is `true`, the returned object will be in the start state;
  /// otherwise, it will be in the same state as this.
  StateMachine<T> copy({bool reset: true});
}

/// Constructs an unambiguous deterministic state machine from a
/// nondeterministic one.
///
/// For any powerset with a non-empty set of [NState.accept] values,
/// [resolveAccept] is called to determine which value is used. The default is
/// to throw a [StateError] when more than one is found.
List<DState<T>> powersetConstruction<T>(List<NState<T>> nfa,
        [T Function(Set<T>) resolveAccept]) =>
    impl.powersetConstruction<T, T>(
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
    impl.powersetConstruction<T, List<T>>(
        nfa, preprocessAccept ?? (accept) => accept.toList());
