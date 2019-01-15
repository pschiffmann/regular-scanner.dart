import '../../state_machine.dart';
import '../range.dart';

// AmbiguousDfa: Dfa<List<T>>
class Dfa<T> implements StateMachine<T> {
  Dfa(this.states)
      : assert(states.isNotEmpty, 'states must not be empty'),
        _current = startState;

  static const int startState = 0;
  static const int errorState = -1;

  final List<DState<T>> states;

  /// Index into [states], or [errorState].
  int _current;

  @override
  bool get inErrorState => _current == errorState;

  @override
  T get accept => inErrorState ? null : states[_current].accept;

  @override
  void moveNext(int input) {
    if (inErrorState) return;
    final state = states[_current];
    final index = binarySearch(state.transitions, input);
    _current = index != errorState
        ? state.transitions[index].successor
        : state.defaultTransition;
  }

  @override
  void reset() => _current = startState;

  @override
  StateMachine<T> copy({bool reset: true}) {
    final result = Dfa(states);
    if (!reset) result._current = _current;
    return result;
  }
}

class DState<T> {
  const DState(this.transitions,
      {this.defaultTransition = Dfa.errorState, this.accept});

  final List<Transition> transitions;

  /// The transition that should be taken if the read character is not in
  /// [transitions]. This value is never `null` and defaults to [Dfa.errorState].
  final int defaultTransition;

  /// If this state is reached, the input matches [accept].
  final T accept;
}

class Transition extends Range {
  const Transition(int min, int max, this.successor) : super(min, max);
  const Transition.single(int value, this.successor) : super.single(value);

  /// The id of the successor state.
  final int successor;

  @override
  String toString() => '${super.toString()} -> successor';
}
