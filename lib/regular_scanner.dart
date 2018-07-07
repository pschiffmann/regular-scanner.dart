///
/// This library shadows the [core.Pattern] class from `dart:core`, so you might
/// want to import it with a prefix:
///
/// ```dart
/// import 'package:regular_scanner/scanner.dart' as rs;
/// ```
library regular_scanner.scanner;

import 'dart:core' hide Pattern;
import 'dart:core' as core show Pattern;

import 'src/dfa.dart' show State, TableDrivenScanner;
import 'src/parser.dart' show parse;
import 'src/powerset_construction.dart' show constructDfa;

export 'src/powerset_construction.dart' show ConflictingPatternException;

/// This annotation marks a `const` variable as an injection point for a
/// [Scanner], and specifies which [Pattern]s that scanner matches.
class InjectScanner {
  const InjectScanner(this.patterns);

  final List<Pattern> patterns;
}

/// Used as an argument to [InjectScanner] to specify the patterns that this
/// [Scanner] matches.
class Pattern {
  const Pattern(this.pattern, {this.precedence: 0}) : assert(precedence >= 0);

  final String pattern;

  final int precedence;

  @override
  String toString() => '/$pattern/';
}

class MatchResult<T extends Pattern> {
  MatchResult(this.pattern, this.length);

  final T pattern;
  final int length;
}

abstract class Scanner<T extends Pattern> {
  factory Scanner(Iterable<Pattern> patterns) => new Scanner.withParseTable(
      constructDfa(patterns.map(parse).toList(growable: false)));

  /// Internal constructor. Only visible so that generated code can instantiate
  /// this class as a `const` expression.
  const factory Scanner.withParseTable(List<State<T>> states) =
      TableDrivenScanner<T>;

  /// Matches [characters] against the patterns in this scanner. Returns the
  /// longest possible match, or `null` if no pattern matched.
  ///
  /// The matching starts at `characters.current`. This means the iterator must
  /// be advanced to a valid state before calling this function. After this
  /// method returns, the position of [characters] will have been advanced at
  /// least [MatchResult.length] positions, but possibly more.
  ///
  /// If [rewind] is `true`, [characters] will be moved back to point exactly
  /// behind the last matched character. This requires [characters] to be a
  /// [BidirectionalIterator].
  ///
  /// To match strings, obtain a compatible iterator from [String.codeUnits] or
  /// [String.runes].
  MatchResult<T> match(Iterator<int> characters, {bool rewind: false});
}
