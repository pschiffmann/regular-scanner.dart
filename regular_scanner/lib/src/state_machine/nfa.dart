import 'package:collection/collection.dart';

import '../../state_machine.dart';
import '../range.dart';

class Nfa<T> implements StateMachine<Set<T>> {
  Nfa(Iterable<NState<T>> startStates)
      : _startState = Set()..add(NStartState(startStates.toList())) {
    _current = startStates;
  }

  Nfa._copy(this._startState) : _current = _startState;

  final Set<NState<T>> _startState;
  Set<NState<T>> _current;
  Set<T> _accept;

  @override
  bool get inErrorState => _current.isEmpty;

  @override
  Set<T> get accept => _accept ??= UnmodifiableSetView(_current
      .map((state) => state.accept)
      .where((accept) => accept != null)
      .toSet());

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
    _current = _startState;
    _accept = null;
  }

  @override
  Nfa<T> copy({bool reset: true}) {
    final result = Nfa._copy(_startState);
    if (!reset) {
      result
        .._current = _current
        .._accept = _accept;
    }
    return result;
  }
}

enum GuardType { value, range, wildcard }

/// Interface that can be implemented by user code.
/// Must use operator== for equality.
class NState<T> {
  // ignore: type_init_formals
  NState.value(int this.guard,
      {this.successors = const [], this.accept, this.negated = false})
      : guardType = GuardType.value;

  NState.range(int min, int max,
      {this.successors = const [], this.accept, this.negated = false})
      : guardType = GuardType.range,
        guard = Range(min, max);

  NState.wildcard({this.successors = const [], this.accept})
      : guardType = GuardType.wildcard,
        guard = null,
        negated = null;

  final GuardType guardType;
  final dynamic/*=int|Range|Null*/ guard;
  final bool negated;
  final Iterable<NState<T>> successors;

  final T accept;
}

class NStartState<T> implements NState<T> {
  NStartState(this.successors);

  @override
  final Iterable<NState<T>> successors;

  @override
  GuardType get guardType => throw UnimplementedError();
  @override
  dynamic get guard => throw UnimplementedError();
  @override
  bool get negated => throw UnimplementedError();
  @override
  T get accept => throw UnimplementedError();
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
