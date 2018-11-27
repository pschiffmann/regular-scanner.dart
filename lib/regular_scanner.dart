library regular_scanner.scanner;

import 'src/dfa.dart' show State, TableDrivenScanner;
import 'src/parser.dart' show parse;
import 'src/powerset_construction.dart' show constructDfa;

export 'src/dfa.dart' show State, Transition;
export 'src/powerset_construction.dart' show ConflictingPatternException;

/// This annotation marks a `const` variable as an injection point for a
/// [Scanner], and specifies which [Regex]s that scanner matches.
class InjectScanner {
  const InjectScanner(this.patterns);

  final List<Regex> patterns;
}

/// Used as an argument to [InjectScanner] to specify the patterns that this
/// [Scanner] matches.
class Regex {
  const Regex(this.regularExpression, {this.precedence = 0})
      : assert(precedence >= 0);

  final String regularExpression;

  final int precedence;

  @override
  String toString() => '/$regularExpression/';
}

/// Returned by [Scanner.match] to indicate which [pattern] matched a given
/// [input].
class MatchResult<T extends Regex> {
  MatchResult(this.pattern, this.input, this.start, this.end)
      : assert(0 <= start && start <= end && end < input.length);

  final T pattern;

  /// The input string that was passed to [Scanner.match].
  final String input;

  /// The span in [input] that was matched by [pattern].
  String get span => input.substring(start, end);

  /// Contains the index (in [String.codeUnits]) of the first matched character.
  final int start;

  /// Contains the index (in [String.codeUnits]) behind the last matched
  /// character.
  final int end;

  /// Returns the number of matched code units.
  int get length => end - start;
}

abstract class Scanner<T extends Regex> {
  factory Scanner(Iterable<T> patterns) {
    final patternsList = List<T>.unmodifiable(patterns);
    assert(patternsList.length == patternsList.toSet().length,
        'patterns contains duplicates');
    return Scanner.withParseTable(patternsList,
        constructDfa(patternsList.map(parse).toList(growable: false)));
  }

  /// Internal constructor. Only visible so that generated code can instantiate
  /// this class as a `const` expression.
  const factory Scanner.withParseTable(
      List<T> patterns, List<State<T>> states) = TableDrivenScanner<T>;

  /// This constructor only exists so this class can be subclassed.
  const Scanner.setPatterns(this.patterns);

  /// The patterns that are matched by this scanner, in unchanged order.
  final List<T> patterns;

  /// Matches [characters] against the patterns in this scanner. Returns the
  /// longest possible match, or `null` if no pattern matched.
  ///
  /// The matching starts at `characters.current`. This means the iterator must
  /// be advanced to a valid state before calling this function. After this
  /// method returns, the position of [characters] will have been advanced at
  /// least [MatchResult.length] positions, but possibly more.
  ///
  /// If [rewind] is `true`, [characters] will be moved back to point exactly
  /// behind the last matched character. This way, the same iterator can be
  /// immediately passed to this method again to match the remaining input.
  /// This requires [characters] to be a [BidirectionalIterator].
  ///
  /// To match strings, obtain a compatible iterator from [String.codeUnits] or
  /// [String.runes].
  MatchResult<T> match(Iterator<int> characters, {bool rewind = false});

  /// Parses the whole input by repeatedly calling [match], until [characters]
  /// is exhausted.
  ///
  /// Calls [onError] if [characters] doesn't match at any point. [onError] is
  /// expected to return a substitute [MatchResult] and advance [characters] by
  /// at least one position. If [onError] is omitted and an error is
  /// encountered, throws a [FormatException].
  Iterable<MatchResult<T>> tokenize(BidirectionalIterator<int> characters,
      {MatchResult<T> Function(BidirectionalIterator<int>) onError}) {
    final result = <MatchResult<T>>[];
    while (characters.current != null) {
      final m = match(characters, rewind: true);
      if (m != null) {
        result.add(m);
      } else if (onError != null) {
        result.add(onError(characters));
      } else {
        throw FormatException("input didn't match any pattern", characters);
      }
    }
    return result;
  }
}
