import 'package:collection/collection.dart';

import '../../state_machine.dart';
import '../range.dart';

class Nfa<T> implements StateMachine<Set<T>> {
  Nfa(this.startStates) : _current = startStates;

  final Set<NState<T>> startStates;
  Set<NState<T>> _current;

  @override
  bool get inErrorState => _current.isEmpty;

  @override
  Set<T> get accept => _accept ??= UnmodifiableSetView(_current
      .map((state) => state.accept)
      .where((accept) => accept != null)
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
    _current = startStates;
    _accept = null;
  }

  @override
  Nfa<T> copy({bool reset: true}) {
    final result = Nfa(startStates);
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
class NState<T> {
  // ignore: type_init_formals
  NState.value(int this.guard, this.successors,
      {this.accept, this.negated = false})
      : guardType = GuardType.value;

  // ignore: type_init_formals
  NState.range(Range this.guard, this.successors,
      {this.accept, this.negated = false})
      : guardType = GuardType.value;

  NState.wildcard(this.successors, [this.accept])
      : guardType = GuardType.value,
        guard = null,
        negated = null;

  NState.start(this.successors, [this.accept])
      : guardType = null,
        guard = null,
        negated = null;

  final GuardType guardType;
  final dynamic/*=int|Range|Null*/ guard;
  final bool negated;
  final Iterable<NState> successors;

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
