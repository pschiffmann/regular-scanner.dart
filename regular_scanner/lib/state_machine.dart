/// An NFA is referenced as an iterable of start [NState]s.
library state_machines;

import 'src/state_machine/nfa.dart';

export 'src/state_machine/dfa.dart';
export 'src/state_machine/nfa.dart';

abstract class StateMachine<T> {
  bool get inErrorState;

  T get accept;

  void moveNext(int input);
  void reset();
  StateMachine<T> copy({bool reset: true});
}
