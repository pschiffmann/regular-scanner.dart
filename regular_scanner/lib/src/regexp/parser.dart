import '../range.dart';
import 'ast.dart';
import 'lexer.dart';
import 'token.dart';

/// Parses [regex] into an [Expression] tree. Throws [FormatException] on
/// invalid regexes, and [RangeError] on unpaired surrogates in [regex].
Expression parse(String regex) {
  final context = TokenIterator(regex);
  if (!context.moveNext()) {
    throw const FormatException('Empty regular expression');
  }
  final expression = parseUnknown(context);
  if (context.current != null) {
    assert(context.current == groupEnd);
    context.error('Unbalanced `)`');
  }

  return expression;
}

Literal parseLiteral(TokenIterator context) {
  assert(context.current == literal);
  return Literal(context.codePoint, parseRepetiton(context..moveNext()));
}

Wildcard parseWildcard(TokenIterator context) {
  assert(context.current == dot);
  return Wildcard(parseRepetiton(context..moveNext()));
}

/// If the current token is a repetition, returns the according [Repetition]
/// constant and advances the token iterator. Else, returns [Repetition.one].
Repetition parseRepetiton(TokenIterator context) {
  switch (context.current) {
    case repetitionPlus:
      context.moveNext();
      return Repetition.oneOrMore;
    case repetitionStar:
      context.moveNext();
      return Repetition.zeroOrMore;
    case repetitionQuestionmark:
      context.moveNext();
      return Repetition.zeroOrOne;
    default:
      return Repetition.one;
  }
}

/// Parses an unknown sequence of expressions until [context] is exhausted or an
/// unbalanced [groupEnd] is found. Creates [Sequence]s and [Alternation]s as
/// needed.
Expression parseUnknown(TokenIterator context) {
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
        sequence.add(parseWildcard(context));
        break;
      case repetitionPlus:
      case repetitionStar:
      case repetitionQuestionmark:
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
        break loop;
      case characterSetStart:
        sequence.add(parseCharacterSet(context));
        break;
      case characterSetEnd:
        context.error('Unbalanced `]`');
        break;
      default:
        throw UnimplementedError('This case is unreachable');
    }
  }
  nextAlternative();

  return alternatives.length == 1
      ? alternatives.first
      : Alternation(alternatives);
}

Group parseGroup(TokenIterator context) {
  assert(context.current == groupStart);

  final startIndex = context.index;
  context.moveNext(onRegexEnd: 'Unclosed `(`');

  final child = parseUnknown(context);

  if (context.current != groupEnd) {
    context.error('Unclosed `(`', startIndex);
  }
  context.moveNext();

  return Group(child, parseRepetiton(context));
}

CharacterSet parseCharacterSet(TokenIterator context) {
  assert(context.current == characterSetStart);
  context.insideCharacterSet = true;

  final startIndex = context.index;
  context.moveNext();

  final negated = context.current == negation;
  if (negated) context.moveNext();

  /// Returns [TokenIterator.codePoint] if the current token is a [literal], and
  /// advances the iterator by one element. Else, throws a [FormatException].
  int readLiteralAdvance() {
    if (context.current == null) {
      context.error('Unclosed `[`', startIndex);
    } else if (context.current != literal) {
      context.error('The special characters `[]^-\` must always be escaped '
          'inside character groups');
    }
    final codeUnit = context.codePoint;
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
  return CharacterSet(ranges,
      negated: negated, repetition: parseRepetiton(context));
}
