library regular_scanner.scanner;

import 'dart:math';

import 'src/dfa.dart' show State, TableDrivenScanner;
import 'src/parser.dart' show parse;
import 'src/powerset_construction.dart' show constructDfa;

export 'src/dfa.dart' show State, Transition;
export 'src/powerset_construction.dart' show ConflictingRegexException;

/// This annotation marks a `const` variable as an injection point for a
/// [Scanner], and specifies which [Regex]s that scanner matches.
class InjectScanner {
  const InjectScanner(this.regexes);

  final List<Regex> regexes;
}

/// Used as an argument to [InjectScanner] to specify the [Regex]es that this
/// [Scanner] matches.
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
      : assert(0 <= start && start <= end && end < input.length);

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
  factory Scanner(Iterable<T> regexes) {
    final regexesList = List<T>.unmodifiable(regexes);
    if (regexesList.length != regexesList.toSet().length)
      throw ArgumentError('regexes contains duplicates');
    return Scanner.withParseTable(regexesList,
        constructDfa(regexesList.map(parse).toList(growable: false)));
  }

  /// Internal constructor. Only visible so that generated code can instantiate
  /// this class as a `const` expression.
  const factory Scanner.withParseTable(List<T> regexes, List<State<T>> states) =
      TableDrivenScanner<T>;

  /// This constructor only exists so this class can be subclassed.
  const Scanner.setRegexes(this.regexes);

  /// The regexes that are matched by this scanner, in unchanged order.
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
