import 'package:collection/collection.dart';

import '../../state_machine.dart';
import '../range.dart';

/// A nondeterministic finite automaton. Because we can't efficiently check
/// whether any given state graph is ambiguous, [accept] always returns
/// `Set<T>`.
class Nfa<T> implements StateMachine<Set<T>> {
  /// Creates a new Nfa that is initially in all [startStates]. The complete
  /// state graph is only implicitly defined by [NState.successors].
  Nfa(Iterable<NState<T>> startStates) : _startStates = startStates.toSet() {
    _current = _startStates;
  }

  Nfa._copy(this._startStates) : _current = _startStates;

  final Set<NState<T>> _startStates;
  Set<NState<T>> _current;

  @override
  bool get inErrorState => _current.isEmpty;

  @override
  Set<T> get accept => _accept ??= UnmodifiableSetView(_current
      .where((state) => state.accept != null)
      .map((state) => state.accept)
      .toSet());
  Set<T> _accept;

  @override
  void moveNext(int input) {
    if (inErrorState) return;
    final next = Set<NState<T>>();
    for (final state in _current) {
      for (final successor in state.successors) {
        if (enterOn(successor, input)) {
          next.add(successor);
        }
      }
    }
    _current = next;
    _accept = null;
  }

  @override
  void reset() {
    _current = _startStates;
    _accept = null;
  }

  @override
  Nfa<T> copy({bool reset = true}) {
    final result = Nfa._copy(_startStates);
    if (!reset) {
      result
        .._current = _current
        .._accept = _accept;
    }
    return result;
  }
}

/// The supported guard types used in [NState.guardType]. See the [NState]
/// constructors for details.
enum GuardType { value, range, wildcard }

/// An instance of this type represents a single state in an [Nfa]. You may
/// instantiate this class directly, or extend or implement it. If you do write
/// your own class, consider that [operator==] is used to determine equality,
/// and keep [guardType] and [guard] consistent.
class NState<T> {
  /// Creates an NState with [guardType] [GuardType.value].
  // ignore: type_init_formals
  NState.value(int this.guard,
      {this.successors = const [], this.accept, this.negated = false})
      : guardType = GuardType.value;

  /// Creates an NState with [guardType] [GuardType.range].
  NState.range(int min, int max,
      {this.successors = const [], this.accept, this.negated = false})
      : guardType = GuardType.range,
        guard = Range(min, max);

  /// Creates an NState with [guardType] [GuardType.wildcard].
  NState.wildcard({this.successors = const [], this.accept})
      : guardType = GuardType.wildcard,
        guard = null,
        negated = null;

  /// Creates an NState without a guard.
  ///
  /// This state may only be used as a start state – if you use it as a
  /// successor of another state, [Nfa.moveNext] will throw an
  /// [UnimplementedError] when trying to process it.
  NState.start({this.successors = const [], this.accept})
      : guardType = null,
        guard = null,
        negated = null;

  /// Indicates how [guard] should be interpreted.
  final GuardType guardType;

  /// The type depends on [guardType]:
  /// - [int] for [GuardType.value]
  /// - [Range] for [GuardType.range]
  /// - `null` for [GuardType.wildcard]
  final dynamic/*=int|Range|Null*/ guard;

  /// If `true`, the state is entered if the current input does **not** match
  /// [guard]; `null` for [GuardType.wildcard] states.
  final bool negated;

  /// Contains the outgoing transitions from this to its successors.
  final Iterable<NState<T>> successors;

  /// A custom object that can be used to mark a state as an accepting state.
  /// If this state is reached, this value is exposed through [Nfa.accept].
  final T accept;
}

// Implementation note: This is not a method on [NState] because we don't want
// that users override only this method and don't implement the `guardType` /
// `guard` / `negated` interface. The powerset_construction library works
// directly on those properties and not on the result of this function.
bool enterOn(NState state, int input) {
  switch (state.guardType) {
    case GuardType.value:
      final guard = state.guard as int;
      return state.negated ? guard != input : guard == input;
    case GuardType.range:
      final guard = state.guard as Range;
      return state.negated ? !guard.contains(input) : guard.contains(input);
    case GuardType.wildcard:
      return true;
    default:
      throw UnimplementedError('`NState.guardType` must not be null');
  }
}
