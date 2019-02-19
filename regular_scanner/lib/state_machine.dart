/// This library exposes the state machines that are used internally by
/// [StateMachineScanner]. You can use them to execute more specialized string
/// matching, as described in the `regular_scanner` library documentation; or
/// to implement your very own classification mechanism that is not even backed
/// by regular expressions.
///
/// When working with an existing state machine, it should be sufficient to read
/// the documentation of the [StateMachine] interface (and the general notes
/// below).
///
/// When you're building the state machine yourself, you have the choice between
/// two implementations of the [StateMachine] interface: [Nfa], which is defined
/// in terms of [NState]s, and [Dfa], which consists of [DState]s. The reason
/// why you might want to use this package instead of simply writing your own
/// state machine is the [powersetConstruction] function, which converts an
/// [Nfa] to an equivalent [Dfa].
///
/// Here are some more general hints that might help you better understand the
/// API, and the rationale behind it.
///  * All state machines in this library are Moore machines – information can
///    only be attached to states, not to transitions.
///  * The documentation uses the term _guard_ to refer to the input annotation
///    of a transition. For example, in a state machine with two states (1) and
///    (2) and a single transition "go from (1) to (2) on input `X`", state (2)
///    is _guarded by `X`_.
///  * All transitions into a state must be guarded by the same symbol. This
///    limitation allows us to store the guard in the state itself. To construct
///    the example above, simply create the states (1) and (2), set (2) as a
///    successor of (1), and set `X` as the guard of (2).
///  * Transitions are optimized for the original use case of this library,
///    regular expressions. Two common regex matchers are natively supported.
///    - The expression `[A-Z]` matches a range of characters. It would be
///      wasteful to represent this as 26 individual transitions, so a state can
///      be guarded by a [Range].
///    - The expression `.` matches any single character and can be represented
///      as [GuardType.wildcard]. It is always taken, regardless of the read
///      input.
///  * To implement perfect guesses at nondeterministic transitions, an [Nfa]
///    can be in multiple states at once. Therefore, it can also be in multiple
///    accepting states at once – the classification performed by the [Nfa] is
///    _ambiguous_.
///
///    Ambiguity can be statically detected by converting the [Nfa] to a [Dfa]
///    with [powersetConstruction]; results from this function are guaranteed to
///    be unambiguous. If you want to store your state machine as a [Dfa] but
///    _retain_ the ambiguity, use [powersetConstructionAmbiguous] instead.
library regular_scanner.state_machine;

import 'regular_scanner.dart';
import 'src/state_machine/dfa.dart';
import 'src/state_machine/nfa.dart';
import 'src/state_machine/powerset_construction.dart' as impl;
import 'src/state_machine/powerset_construction.dart'
    show AmbiguousInputException;

export 'src/range.dart' show Range;
export 'src/state_machine/dfa.dart' show Dfa, DState, Transition;
export 'src/state_machine/nfa.dart' show Nfa, NState, GuardType;
export 'src/state_machine/powerset_construction.dart'
    show AmbiguousInputException;

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
/// transition, it reaches an _error state_. This is observable for callers
/// through [inErrorState]. An error state can't be exited by [moveNext], but
/// the method can still be called.
abstract class StateMachine<T> {
  /// While in an error state, [accept] will always be `null`.
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
  StateMachine<T> copy({bool reset = true});
}

/// Constructs an unambiguous deterministic state machine from a
/// nondeterministic one.
///
/// For each [DState], [resolveAccept] is called to determine which
/// [NState.accept] value is used as [DState.accept]. The default is to throw an
/// [AmbiguousInputException] when more than one is found.
Dfa<T> powersetConstruction<T>(List<NState<T>> nfa,
    [T Function(Set<T>) resolveAccept]) {
  T defaultResolveAccept(Set<T> accept) {
    switch (accept.length) {
      case 0:
        return null;
      case 1:
        return accept.first;
      default:
        throw AmbiguousInputException(accept);
    }
  }

  return impl.powersetConstruction<T, T>(
      nfa, resolveAccept ?? defaultResolveAccept);
}

/// Constructs an ambiguous deterministic state machine from a nondeterministic
/// one.
///
/// For each [DState], the set of [NState.accept] values is passed to
/// [preprocessAccept] and the result is used as the [DState.accept] in the
/// resolved DFA state. This function can be used to filter out certain values,
/// or to arrange them in a desired order. The default is to return all values
/// in an undefined order.
Dfa<List<T>> powersetConstructionAmbiguous<T>(List<NState<T>> nfa,
    [List<T> Function(Set<T>) preprocessAccept]) {
  List<T> defaultPreprocessAccept(Set<T> accept) =>
      accept.isEmpty ? null : accept.toList();

  return impl.powersetConstruction<T, List<T>>(
      nfa, preprocessAccept ?? defaultPreprocessAccept);
}
