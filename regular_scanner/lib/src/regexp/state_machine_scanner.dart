import '../../regular_scanner.dart';
import '../../state_machine.dart';

abstract class StateMachineScannerBase<T> extends Scanner<T> {
  const StateMachineScannerBase();

  StateMachine<T> get stateMachine;

  @override
  ScannerMatch<T> matchAsPrefix(String string, [int start = 0]) {
    RangeError.checkValueInInterval(start, 0, string.length, 'string');

    final sm = stateMachine;
    var accept = sm.accept;
    var end = start;

    final runes = RuneIterator.at(string, start);
    while (runes.moveNext()) {
      sm.moveNext(runes.current);
      if (sm.inErrorState) break;
      if (sm.accept != null) {
        accept = sm.accept;
        end = runes.rawIndex + runes.currentSize;
      }
    }

    return accept == null
        ? null
        : ScannerMatch(this, accept, string, start, end);
  }
}

class StateMachineScanner<T> extends StateMachineScannerBase<T> {
  StateMachineScanner(this._stateMachine);

  final StateMachine<T> _stateMachine;

  @override
  StateMachine<T> get stateMachine => _stateMachine.copy();
}

class BuiltScanner<T> extends StateMachineScannerBase<T> {
  const BuiltScanner(this.states);

  final List<DState<T>> states;

  @override
  Dfa<T> get stateMachine => Dfa(states);
}
