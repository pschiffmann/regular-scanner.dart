import '../../state_machine.dart';
import '../range.dart';

class Nfa<T> implements StateMachine<T> {
  Nfa(this.states);

  final Set<NState<T>> states;

  @override
  MatchResult<T> matchAsPrefix(Iterable<int> sequence, [int start = 0]) {
    var current = states, next = states;
    for (final value in sequence) {
      current = next;
      next = Set<NState<T>>();
      for (final state in current) {
        for (final successor in state.successors) {
          if (successor.guard.contains(value)) {
            next.add(successor);
          }
        }
      }
    }
    return null;
  }

  @override
  Iterable<MatchResult<T>> matchesAt(Iterable<int> sequence, int start) =>
      throw UnimplementedError();
}

enum GuardType { value, range, wildcard }

/// Interface that can be implemented by user code.
class NState<T> {
  // ignore: type_init_formals
  NState.value(int this.guard, this.successors, [this.accept])
      : guardType = GuardType.value;

  // ignore: type_init_formals
  NState.range(Range this.guard, this.successors, [this.accept])
      : guardType = GuardType.value;

  NState.wildcard(this.successors, [this.accept])
      : guardType = GuardType.value,
        guard = null;

  NState.start(this.successors, [this.accept])
      : guardType = null,
        guard = null;

  final GuardType guardType;
  final/*=int|Range|Null*/ guard;
  final Iterable<NState> successors;

  final T accept;
}
