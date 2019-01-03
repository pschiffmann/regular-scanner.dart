import '../../regular_scanner.dart';
import '../range.dart';

class State<T extends Regex> {
  const State(this.transitions,
      {this.defaultTransition = State.errorId, this.accept});

  /// The state in [TableDrivenScanner.states] at index `0` is the start state.
  static const int startId = 0;

  /// [successorFor] returns this value to reject the next character and stop
  /// the match process.
  static const int errorId = -1;

  final List<Transition> transitions;

  /// The transition that should be taken if the read character is not in
  /// [transitions]. This value is never `null` and defaults to [State.errorId].
  final int defaultTransition;

  /// If this state is reached, the input matches [accept].
  final T accept;

  int successorFor(int guard) {
    final index = binarySearch(transitions, guard);
    return index == errorId ? defaultTransition : transitions[index].successor;
  }
}

class Transition extends Range {
  const Transition(int min, int max, this.successor) : super(min, max);
  const Transition.single(int value, this.successor) : super.single(value);

  /// The id of the successor state.
  final int successor;

  @override
  String toString() => min == max
      ? '${String.fromCharCode(min)} -> $successor'
      : '[${String.fromCharCode(min)}-${String.fromCharCode(max)}] '
      '-> $successor';
}

class TableDrivenScanner<T extends Regex> extends Scanner<T> {
  const TableDrivenScanner(this.regexes, this.states);

  @override
  final List<T> regexes;

  final List<State<T>> states;

  @override
  ScannerMatch<T> matchAsPrefix(final String string, [final int start = 0]) {
    RangeError.checkValueInInterval(start, 0, string.length, 'string');

    var state = states[State.startId];
    var position = start;
    var result = state.accept == null
        ? null
        : ScannerMatch(this, state.accept, string, start, start);
    while (position < string.length) {
      final nextId = state.successorFor(string.codeUnitAt(position));
      if (nextId == State.errorId) {
        break;
      }
      state = states[nextId];
      position++;
      if (state.accept != null) {
        result = ScannerMatch(this, state.accept, string, start, position);
      }
    }

    return result;
  }
}
