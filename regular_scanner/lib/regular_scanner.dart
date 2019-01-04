library regular_scanner;

import 'dart:math';

import 'src/regexp/parser.dart' show parse;
import 'src/state_machine/dfa.dart' show TableDrivenScanner;
import 'src/state_machine/powerset_construction.dart' show constructDfa;
import 'state_machine.dart';

class Regex {
  const Regex(this.regularExpression, {this.precedence = 0})
      : assert(precedence >= 0);

  final String regularExpression;

  final int precedence;

  @override
  String toString() => '/$regularExpression/';
}

/// Returned by [Scanner.matchAsPrefix] to indicate which [regex] matched a
/// given [input].
class ScannerMatch<T extends Regex> implements Match {
  ScannerMatch(this.pattern, this.regex, this.input, this.start, this.end)
      : assert(0 <= start && start <= end && end <= input.length);

  @override
  final Scanner<T> pattern;
  @override
  final String input;
  @override
  final int start;
  @override
  final int end;

  final T regex;

  /// The span in [input] that was matched by [regex].
  String get capture => input.substring(start, end);

  /// Returns the length of [capture].
  int get length => end - start;

  /// Returns [capture] if [group] is 0. Else, throws [RangeError].
  @override
  String group(int group) =>
      group == 0 ? capture : (throw RangeError.value(group));
  @override
  String operator [](int group) => this.group(group);
  @override
  List<String> groups(List<int> groupIndices) =>
      groupIndices.map(group).toList(growable: false);

  /// Always returns 0 because [Scanner] doesn't support capturing groups.
  @override
  int get groupCount => 0;
}

abstract class Scanner<T extends Regex> implements Pattern {
  /// Empty constructor allows extending this class, which can be used to
  /// inherit [allMatches].
  const Scanner(this.regexes);

  factory Scanner.deterministic(Iterable<T> regexes) {
    final regexesList = List<T>.unmodifiable(regexes);
    if (regexesList.length != regexesList.toSet().length)
      throw ArgumentError('regexes contains duplicates');
    return TableDrivenScanner(regexesList,
        constructDfa(regexesList.map(parse).toList(growable: false)));
  }

  /// The regexes that are matched by this scanner.
  final List<T> regexes;

  @override
  Iterable<ScannerMatch<T>> allMatches(String string, [int start = 0]) sync* {
    while (start < string.length) {
      final match = matchAsPrefix(string, start);
      if (match != null) {
        yield match;
        start += max(match.length, 1);
      } else {
        start++;
      }
    }
  }

  @override
  ScannerMatch<T> matchAsPrefix(String string, [int start = 0]);
}

class StateMachineScanner<T extends Regex> extends Scanner<T> {
  const StateMachineScanner(this.stateMachine, [List<Regex> regexes])
      : super(regexes);

  final StateMachine<T> stateMachine;

  @override
  ScannerMatch<T> matchAsPrefix(String string, [int start = 0]) {
    final match = stateMachine.matchAsPrefix(string.codeUnits, start);
    return match == null
        ? null
        : ScannerMatch(this, match.accept, string, match.start, match.end);
  }
}
