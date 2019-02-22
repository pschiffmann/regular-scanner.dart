/// Use this library to construct regex scanners at runtime. If your [Regex]es
/// are known at build time, consider using package `regular_scanner_builder`
/// and the `built_scanner` library from this package.
///
/// A [Scanner] matches input strings against multiple regular expressions
/// concurrently. [Scanner] implements [Pattern], so you can use it in places
/// like [String.indexOf] and [String.replaceAllMapped]. The match methods
/// return [ScannerMatch]es, so you can use [ScannerMatch.regex] to find out
/// _which_ regex matched the input.
///
/// [Regex]es are compiled to [StateMachine]s. The state machine is explicitly
/// part of the public API and can be used in situations where
/// [Scanner.matchAsPrefix] is too limited. Two examples are given below.
///
/// The [Scanner.stateMachine] state transitions are [Unicode code points][1].
/// Byte sequences must be decoded to code points before they can be matched
/// against the state machine. [Scanner.matchAsPrefix] and [Scanner.allMatches]
/// do this automatically, but if you use the state machine directly, you need
/// to do it yourself. If you match a [String], use [String.runes]; if you match
/// some other input (for example a `List` or `Stream` of bytes), package:utf
/// might be helpful.
///
/// The supported regular expression syntax is listed in the package README. For
/// more information on the [StateMachine] API, refer to the `state_machine`
/// library of this package.
///
/// [1]: http://unicode.org/glossary/#code_point
///
/// ## Examples
///
/// ### Execute code based on which pattern matched: use a switch statement
///
/// If you define your regexes as `const` variables, you can use them in a
/// switch/case statement.
///
/// ```dart
/// const usd = Regex(r'$[0-9]+ USD');
/// const cad = Regex(r'$[0-9]+ CAD');
/// const eur = Regex(r'[0-9]+€');
/// const gbp = Regex(r'£[0-9]+');
/// final scanner = Scanner.unambiguous([usd, cad, eur, gbp]);
///
/// String detectCurrency(String userInput) {
///   final match = scanner.matchAsPrefix(userInput);
///   if (match == null || match.end != userInput.length) {
///     throw FormatException('Unsupported format');
///   }
///   switch(match.regex) {
///     case usd:
///       return 'USD';
///     case cad:
///       return 'CAD';
///     case eur:
///       return 'EUR';
///     case gbp:
///       return 'GBP';
///     default:
///       throw UnimplementedError('This case should be unreachable.');
///   }
/// }
/// ```
///
/// ### Execute code based on which pattern matched: subclass `Regex`
///
/// Alternatively, you can rewrite the example above and extend [Regex] to
/// attach information to the pattern directly.
///
/// ```dart
/// class CurrencyPattern extends Regex {
///   CurrencyPattern(String regex, this.currency) : super(regex);
///
///   final String currency;
/// }
///
/// final scanner = Scanner.unambiguous([
///   CurrencyPattern(r'$[0-9]+ USD', 'USD'),
///   CurrencyPattern(r'$[0-9]+ CAD', 'CAD'),
///   CurrencyPattern(r'[0-9]+€', 'EUR'),
///   CurrencyPattern(r'[0-9]+', 'GBP'),
/// ]);
///
/// String detectCurrency(String userInput) {
///   final match = scanner.matchAsPrefix(userInput);
///   if (match == null || match.end != userInput.length) {
///     throw FormatException('Unsupported format');
///   }
///   return match.regex.currency;
/// }
/// ```
///
/// ### Match a stream
///
/// If you want to match an input sequence that is not a [String], use the
/// [Scanner.stateMachine] directly.
///
/// ```dart
/// const word = Regex('[A-Za-z]+');
/// const other = Regex('[^A-Za-z]+');
/// final scanner = Scanner.unambiguous([word, other]);
///
/// Stream<String> findWords(Stream<int> codePoints) async* {
///   final sm = scanner.stateMachine;
///   final buffer = StringBuffer();
///   await for (final codePoint in codePoints) {
///     sm.moveNext(codePoint);
///     if (sm.inErrorState) {
///       if (buffer.isNotEmpty) {
///         yield buffer.toString();
///         buffer.clear();
///       }
///     } else {
///       buffer.writeCharCode(codePoint);
///     }
///   }
///   if (buffer.isNotEmpty) yield buffer.toString();
/// }
/// ```
///
/// ### Find the highest precedence match, regardless of length
///
/// [Scanner.matchAsPrefix] is greedy: If different patterns match at different
/// indexes into the input string, it will return the _longest_ match.
///
/// This function demonstrates how you can use the underlying [Dfa] to return
/// the match with the highest [Regex.precedence], even if another regex could
/// produce a longer match.
///
/// ```dart
/// ScannerMatch<T> highestPrecedenceMatch(Scanner<T> scanner, String input) {
///   RangeError.checkValueInInterval(start, 0, string.length, 'string');
///
///   final sm = stateMachine();
///   var accept = sm.accept;
///   var end = start;
///
///   final runes = RuneIterator.at(string, start);
///   while (runes.moveNext()) {
///     sm.moveNext(runes.current);
///     if (sm.inErrorState) break;
///     if (sm.accept != null &&
///           (accept == null || accept.precedence < sm.accept.precedence)) {
///       accept = sm.accept;
///       end = runes.rawIndex + runes.currentSize;
///     }
///   }
///
///   return accept == null
///       ? null
///       : ScannerMatch(this, accept, string, start, end);
/// }
/// ```
library regular_scanner;

import 'dart:math';

import 'src/regexp/ast_to_nfa.dart';
import 'src/regexp/explain_ambiguity.dart';
import 'src/regexp/parser.dart';
import 'src/regexp/state_machine_scanner.dart';
import 'state_machine.dart';

export 'src/regexp/explain_ambiguity.dart' show AmbiguousRegexException;
export 'src/regexp/state_machine_scanner.dart' show StateMachineScanner;

/// Defines a regular expression for use by [Scanner].
///
/// The syntax recognized in [Regex] is different from the one supported by
/// [RegExp]. Refer to the package documentation for details.
///
/// This class does not implement [Pattern] and can't be used to match a string
/// directly. It's only purpose is to store meta information for [Scanner] –
/// [precedence], to be exact. The class exposes a `const` constructor, so you
/// can use instances of this type in a `switch` statement.
///
/// You may extend this type to attach additional information or behaviour to
/// your patterns. It can later be accessed through [ScannerMatch.regex]. Do not
/// `implement` this class, because package `regular_scanner_builder` can't
/// handle it.
class Regex {
  const Regex(this.pattern, {this.precedence = 0}) : assert(precedence >= 0);

  /// The regular expression pattern of this regex. Refer to the package
  /// documentation for the supported syntax.
  final String pattern;

  /// This value is used to resolve ambiguity if two patterns match the same
  /// input – in that case, the regex with the higher precedence is chosen.
  final int precedence;

  @override
  String toString() => '/$pattern/';
}

/// Returned by [Scanner.matchAsPrefix] and [Scanner.allMatches] to indicate
/// which [regex] matched a given [input].
class ScannerMatch<T> implements Match {
  ScannerMatch(this.pattern, this.regex, this.input, this.start, this.end)
      : assert(0 <= start && start <= end && end <= input.length);

  @override
  final Scanner pattern;
  @override
  final String input;
  @override
  final int start;
  @override
  final int end;

  /// The exact [Regex] that matched [input].
  ///
  /// The type of this object depends on the scanner you used to find the match.
  /// It will be
  /// - [Regex] for [Scanner.unambiguous],
  /// - `List<Regex>` for [Scanner.ambiguous],
  /// - `Set<Regex>` for [Scanner.nondeterministic].
  ///
  /// If you subclassed [Regex], the static type will be your type instead of
  /// [Regex].
  final T regex;

  /// The span in [input] that was matched by [regex]. Alias for `group(0)`.
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

/// A scanner is constructed from a collection of [Regex]es and matches input
/// strings against all of them concurrently.
///
/// Scanners created at runtime are [StateMachineScanner]s. Scanners generated
/// at build time by package `regular_scanner_builder` are [BuiltScanner]s. In
/// general, you shouldn't use the constructors directly; instead, use the
/// factory functions [unambiguous], [ambiguous] and [nondeterministic]. They
/// will infer the generic types from the function parameter.
///
/// [T] is the type of the [ScannerMatch.regex] value of the matches obtained
/// from this scanner. For [unambiguous] scanners it is a subclass of [Regex],
/// for [ambiguous] scanners it is a `List<Regex`, and for [nondeterministic]
/// scanners it is a `Set<Regex>`.
abstract class Scanner<T, S extends StateMachine<T>> implements Pattern {
  /// Empty constructor allows extending this class, which can be used to
  /// inherit [allMatches].
  const Scanner();

  /// Returns a new state machine that accepts the union over all [Regex]es this
  /// scanner was constructed from.
  S stateMachine();

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
  ScannerMatch<T> matchAsPrefix(String string, [int start = 0]) {
    RangeError.checkValueInInterval(start, 0, string.length, 'string');

    final sm = stateMachine();
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

  /// Generates an unambiguous scanner backed by a [Dfa].
  ///
  /// If a string is matched by multiple [regexes], the one with the highest
  /// [Regex.precedence] is chosen. If the precedence is ambiguous, throws an
  /// [AmbiguousRegexException].
  static StateMachineScanner<R, Dfa<R>> unambiguous<R extends Regex>(
          Iterable<R> regexes) =>
      StateMachineScanner(
          powersetConstruction(_compile(regexes), highestPrecedenceRegex));

  /// Generates an ambiguous scanner backed by a [Dfa].
  ///
  /// If a string is matched by multiple [regexes], all regexes are used,
  /// ordered by [Regex.precedence] descending. If the ordering is ambiguous,
  /// throws an [AmbiguousRegexException].
  static StateMachineScanner<List<R>, Dfa<List<R>>> ambiguous<R extends Regex>(
          Iterable<R> regexes) =>
      StateMachineScanner(
          powersetConstructionAmbiguous(_compile(regexes), orderByPrecedence));

  /// Generates an ambiguous scanner backed by an [Nfa].
  ///
  /// This is the fastest to generate, and _may_ require less memory than the
  /// [Dfa]-backed variants, but it does not perform any ambiguity checks.
  static StateMachineScanner<Set<R>, Nfa<R>> nondeterministic<R extends Regex>(
          Iterable<R> regexes) =>
      StateMachineScanner(Nfa(_compile(regexes)));
}

List<NState<T>> _compile<T extends Regex>(Iterable<T> regexes) {
  final startStates = <NState<T>>[];
  for (final regex in regexes) {
    final ast = parse(regex.pattern);
    startStates.add(astToNfa(ast, regex));
  }
  return startStates;
}
