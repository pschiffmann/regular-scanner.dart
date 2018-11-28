library regular_scanner.scanner;

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

/// Returned by [Scanner.match] to indicate which [regex] matched a given
/// [input].
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
  Iterable<ScannerMatch> allMatches(String string, [int start = 0]) =>
      throw UnimplementedError();

  @override
  ScannerMatch matchAsPrefix(String string, [int start = 0]) =>
      throw UnimplementedError();

  /// Matches [characters] against the [regexes]. Returns the longest possible
  /// match, or `null` if no regex matched.
  ///
  /// The matching starts at `characters.current`. This means the iterator must
  /// be advanced to a valid state before calling this function. After this
  /// method returns, the position of [characters] will have been advanced at
  /// least [ScannerMatch.length] positions, but possibly more.
  ///
  /// If [rewind] is `true`, [characters] will be moved back to point exactly
  /// behind the last matched character. This way, the same iterator can be
  /// immediately passed to this method again to match the remaining input.
  /// This requires [characters] to be a [BidirectionalIterator].
  ///
  /// To match strings, obtain a compatible iterator from [String.codeUnits] or
  /// [String.runes].
  ScannerMatch<T> match(Iterator<int> characters, {bool rewind = false});

  /// Parses the whole input by repeatedly calling [match], until [characters]
  /// is exhausted.
  ///
  /// Calls [onError] if [characters] doesn't match at any point. [onError] is
  /// expected to return a substitute [ScannerMatch] and advance [characters] by
  /// at least one position. If [onError] is omitted and an error is
  /// encountered, throws a [FormatException].
  Iterable<ScannerMatch<T>> tokenize(BidirectionalIterator<int> characters,
      {ScannerMatch<T> Function(BidirectionalIterator<int>) onError}) {
    final result = <ScannerMatch<T>>[];
    while (characters.current != null) {
      final m = match(characters, rewind: true);
      if (m != null) {
        result.add(m);
      } else if (onError != null) {
        result.add(onError(characters));
      } else {
        throw FormatException("input didn't match any regex", characters);
      }
    }
    return result;
  }
}
