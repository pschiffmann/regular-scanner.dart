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

import 'src/dfa.dart' show State;
import 'src/parser.dart' show parse;
import 'src/powerset_construction.dart' show constructDfa;

/// This annotation marks a `const` variable as an injection point for a
/// [Scanner], and specifies which [Pattern]s that scanner matches.
class InjectScanner {
  const InjectScanner(this.patterns);

  final List<Pattern> patterns;
}

/// Used as an argument to [InjectScanner] to specify the patterns that this
/// [Scanner] matches.
class Pattern {
  const Pattern(this.pattern, {this.precedence});

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

class Scanner<T extends Pattern> {
  factory Scanner(Iterable<Pattern> patterns) => new Scanner.withParseTable(
      constructDfa(patterns.map(parse).toList(growable: false)));

  /// Internal constructor. Only visible so that generated code can instantiate
  /// this class as a `const` expression.
  const Scanner.withParseTable(this.states);

  final List<State<T>> states;

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
  MatchResult<T> match(Iterator<int> characters, {bool rewind: false}) {
    var nextState = State.startId;
    var steps = 0;
    MatchResult<T> result;
    while (nextState != State.errorId && characters.current != null) {
      final state = states[nextState];
      if (state.accept != null) {
        result = new MatchResult(state.accept, steps);
      }

      nextState = state.successorFor(characters.current);
      characters.moveNext();
      steps++;
    }

    if (rewind) {
      final it = characters as BidirectionalIterator;
      final stepsBack = result == null ? steps : steps - result.length;
      for (var i = 0; i < stepsBack; i++) {
        it.movePrevious();
      }
    }
    return result;
  }
}
