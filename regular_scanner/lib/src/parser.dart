import 'package:charcode/ascii.dart';
import 'package:meta/meta.dart' hide literal;

import '../regular_scanner.dart' show Regex;
import 'ast.dart';
import 'ranges.dart';
import 'scanner.dart';

/// Parses [regex] into an [Expression] tree. Throws [FormatException] on
/// invalid regexes, and [RangeError] on unpaired surrogates in [regex].
Root parse(Regex regex) {
  final context = TokenIterator(regex.regularExpression);
  if (!context.moveNext()) {
    throw FormatException('Empty regular expression', regex.regularExpression);
  }
  final expression = parseUnknown(context, expectGroupEnd: false);
  assert(context.current == null);

  return Root(expression, regex);
}

Expression /* Literal|Sequence */ parseLiteral(TokenIterator context) {
  assert(context.current == literal);
  return context.literalIsSingleCodeUnit
      ? Literal(context.codeUnit, parseRepetiton(context..moveNext()))
      : Sequence(context.codeUnits.map((int codeUnit) => Literal(codeUnit)),
          parseRepetiton(context..moveNext()));
}

Dot parseDot(TokenIterator context) {
  assert(context.current == dot);
  return Dot(parseRepetiton(context..moveNext()));
}

/// If the current token is a [repetition], returns the according repetition
/// constant and advances the token iterator. Else, returns [Repetition.one].
Repetition parseRepetiton(TokenIterator context) {
  if (context.current != repetition) {
    return Repetition.one;
  }
  final char = context.codeUnit;
  context.moveNext();
  switch (char) {
    case $plus:
      return Repetition.oneOrMore;
    case $question:
      return Repetition.zeroOrOne;
    case $asterisk:
      return Repetition.zeroOrMore;
    default:
      throw UnimplementedError('This case is unreachable');
  }
}

/// Parses an unknown sequence of expressions until [context] is exhausted.
/// Creates [Sequence]s and [Alternation]s as needed, or returns a [State] if
/// only a single state pattern was found.
///
/// If [expectGroupEnd] is `true`, stops parsing when reaching the first
/// [groupEnd]. Else, throws a [FormatException] when finding that
/// character.
Expression parseUnknown(TokenIterator context,
    {@required bool expectGroupEnd}) {
  assert(context.current != null);

  // All fully parsed [choice]-separated expressions found so far.
  final alternatives = <Expression>[];
  // The currently parsed sequence.
  final sequence = <Expression>[];

  void nextAlternative() {
    switch (sequence.length) {
      case 0:
        context.error('Empty alternative');
        break;
      case 1:
        alternatives.add(sequence.first);
        break;
      default:
        alternatives.add(Sequence(sequence));
        break;
    }
    sequence.clear();
  }

  loop:
  while (context.current != null) {
    switch (context.current) {
      case literal:
        sequence.add(parseLiteral(context));
        break;
      case dot:
        sequence.add(parseDot(context));
        break;
      case repetition:
        context.error('Unescaped repetition character');
        break;
      case choice:
        nextAlternative();
        context.moveNext();
        break;
      case groupStart:
        sequence.add(parseGroup(context));
        break;
      case groupEnd:
        if (!expectGroupEnd) {
          context.error('Unbalanced `)`');
        }
        break loop;
      case characterSetStart:
        sequence.add(parseCharacterSet(context));
        break;
      case characterSetEnd:
        context.error('Unbalanced `]`');
        break;
      case characterSetAlias:
        throw UnimplementedError(
            'Currently not supported. This will be implemented as part of '
            'https://github.com/pschiffmann/regular-scanner.dart/issues/5');
      default:
        throw UnimplementedError('This case is unreachable');
    }
  }
  nextAlternative();

  return alternatives.length == 1
      ? alternatives.first
      : Alternation(alternatives);
}

Expression parseGroup(TokenIterator context) {
  assert(context.current == groupStart);

  final startIndex = context.index;
  context.moveNext(onRegexEnd: 'Unclosed `(`');

  final result = parseUnknown(context, expectGroupEnd: true);

  if (context.current != groupEnd) {
    context.error('Unclosed `(`', startIndex);
  }
  context.moveNext();

  return result..repetition |= parseRepetiton(context);
}

CharacterSet parseCharacterSet(TokenIterator context) {
  assert(context.current == characterSetStart);
  context.insideCharacterSet = true;

  final startIndex = context.index;
  context.moveNext();

  final negated = context.current == negation;
  if (negated) context.moveNext();

  /// Returns [TokenIterator.codeUnit] if the current token is a [literal], and
  /// advances the iterator by one element. Else, throws a [FormatException].
  int readLiteralAdvance() {
    if (context.current == null) {
      context.error('Unclosed `[`', startIndex);
    } else if (context.current != literal) {
      context.error('The special characters `[]^-\` must always be escaped '
          'inside character groups');
    } else if (!context.literalIsSingleCodeUnit) {
      context.error('Surrogate characters are currently not supported: '
          'https://github.com/pschiffmann/regular-scanner.dart/issues/7');
    }
    final codeUnit = context.codeUnit;
    context.moveNext();
    return codeUnit;
  }

  final ranges = <Range>[];
  while (context.current != characterSetEnd) {
    final lowerBound = readLiteralAdvance();
    if (context.current != rangeSeparator) {
      ranges.add(Range.single(lowerBound));
      continue;
    }
    context.moveNext();
    ranges.add(Range(lowerBound, readLiteralAdvance()));
  }
  context
    ..insideCharacterSet = false
    ..moveNext();
  return CharacterSet(ranges, negated)..repetition = parseRepetiton(context);
}
