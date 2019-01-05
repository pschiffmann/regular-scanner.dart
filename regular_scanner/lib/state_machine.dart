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
/// One final note about naming: guards
library state_machines;

import 'regular_scanner.dart';
import 'src/state_machine/nfa.dart';
import 'src/state_machine/powerset_construction.dart';

export 'src/state_machine/dfa.dart';
export 'src/state_machine/nfa.dart';
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
