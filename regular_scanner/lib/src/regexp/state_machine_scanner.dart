import '../../regular_scanner.dart';
import '../../state_machine.dart';

class StateMachineScanner<T, S extends StateMachine<T>> extends Scanner<T, S> {
  StateMachineScanner(this._stateMachine);

  final S _stateMachine;

  @override
  S stateMachine() => _stateMachine.copy() as S;
}

///
class BuiltScanner<T> extends Scanner<T, Dfa<T>> {
  const BuiltScanner(this.states);

  /// The [Dfa.states] of [stateMachine].
  final List<DState<T>> states;

  @override
  Dfa<T> stateMachine() => Dfa(states);
}
