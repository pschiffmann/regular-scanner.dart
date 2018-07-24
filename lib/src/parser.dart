import 'dart:core' hide Pattern;

import 'package:charcode/ascii.dart';
import 'package:meta/meta.dart';

import '../regular_scanner.dart' show Pattern;
import 'ast.dart';
import 'ranges.dart';

enum TokenType {
  /// Characters that only match themselves.
  literal,

  /// `.` matches any character.  Only  recognized while
  /// [TokenIterator.insideCharacterSet] is `false`.
  dot,

  /// `+`, `*` and `?` repetition modifiers.  Only  recognized while
  /// [TokenIterator.insideCharacterSet] is `false`.
  repetition,

  /// `|` separates two alternative patterns.  Only recognized while
  /// [TokenIterator.insideCharacterSet] is `false`.
  alternation,

  /// `(` starts a group that can be repeated as a whole. Only recognized while
  /// [TokenIterator.insideCharacterSet] is `false`.
  groupStart,

  /// `)` marks the end of a [groupStart]. Only recognized while
  /// [TokenIterator.insideCharacterSet] is `false`.
  groupEnd,

  /// `[` starts a [CharacterSet].
  characterSetStart,

  /// `]` marks the end of a [characterSetStart].
  characterSetEnd,

  /// `-` separates the lower and upper bounds in a [CharacterSet] range. Only
  /// recognized while [TokenIterator.insideCharacterSet] is `true`.
  rangeSeparator,

  /// `^` as the first character in a [CharacterSet] sets [CharacterSet.negated]
  /// to `true`. Only recognized while  [TokenIterator.insideCharacterSet] is
  /// `true`.
  setNegation
}

const List<int> escapeNormal = const [$backslash];
const List<int> escapeCharacterSet = const [$backslash];

/// Presents [pattern] as a sequence of regular expression tokens. [current]
/// contains the rune, or lexeme, and [type] contains the resolved type for that
/// token. Backslash-escaped characters are recognized as [TokenType.literal]
/// tokens, and the escape characters are not exposed as iteration elements.
class TokenIterator implements Iterator<int> {
  TokenIterator(this.pattern) : _runes = new RuneIterator(pattern);

  /// This string that is scanned by this iterator.
  final String pattern;

  /// [String.runes] of [pattern].
  final RuneIterator _runes;

  /// The resolved type of [current].
  TokenType get type => _type;
  TokenType _type;

  /// This flag changes which characters are recognized as [TokenType.literal]s
  /// or special characters. It is set by [parseCharacterSet].
  bool insideCharacterSet = false;

  @override
  int get current => _runes.current;

  /// Forwards [RuneIterator.rawIndex].
  int get index => _runes.rawIndex;

  /// Reads the next character from [pattern] and updates [type]. If there is no
  /// next character and [onEndOfString] is not `null`, throws a
  /// [FormatException] with [onEndOfString] as message.
  @override
  bool moveNext({String onEndOfString}) {
    if (!_runes.moveNext()) {
      if (onEndOfString != null) error(onEndOfString, pattern.length - 1);
      _type = null;
      return false;
    }
    _type =
        insideCharacterSet ? _resolveTypeCharacterSet() : _resolveTypeNormal();
    return true;
  }

  /// Resolve the [type] of [current] while [insideCharacterSet] is `false`.
  TokenType _resolveTypeNormal() {
    switch (current) {
      case $backslash:
        if (!_runes.moveNext()) {
          error(
              r'An escape character `\` must not be '
              'the last character in a pattern',
              pattern.length - 1);
        }
        if (!escapeNormal.contains(current)) {
          // error(r'Unrecognized escape sequence `\$char`');
        }
        continue literal;
      case $bar:
        return TokenType.alternation;
      case $lparen:
        return TokenType.groupStart;
      case $rparen:
        return TokenType.groupEnd;
      case $lbracket:
        return TokenType.characterSetStart;
      case $rbracket:
        return TokenType.characterSetEnd;
      case $asterisk:
      case $plus:
      case $question:
        return TokenType.repetition;
      case $dot:
        return TokenType.dot;
      literal:
      default:
        return TokenType.literal;
    }
    throw new UnimplementedError('This line is unreachable');
  }

  /// Resolve the [type] of [current] while [insideCharacterSet] is `true`.
  TokenType _resolveTypeCharacterSet() {
    switch (current) {
      case $backslash:
        if (!_runes.moveNext()) {
          error(
              r'An escape character `\` must not be '
              'the last character in a pattern',
              pattern.length - 1);
        }
        if (!escapeCharacterSet.contains(current)) {
          // error(r'Unrecognized escape sequence `\$char`');
        }
        continue literal;
      case $lbracket:
        return TokenType.characterSetStart;
      case $rbracket:
        return TokenType.characterSetEnd;
      case $minus:
        return TokenType.rangeSeparator;
      case $caret:
        return TokenType.setNegation;
      literal:
      default:
        return TokenType.literal;
    }
    throw new UnimplementedError('This line is unreachable');
  }

  /// Convenience method to throw a [FormatException] with [message] and
  /// [offset]. Uses the rune index of [current] if [offset] is omitted.
  @alwaysThrows
  void error(String message, [int offset]) =>
      throw new FormatException(message, pattern, offset ?? index);
}

/// Parses [pattern] into an [Expression] tree. Throws a [FormatException] on
/// invalid patterns.
Root parse(Pattern pattern) {
  final context = new TokenIterator(pattern.regularExpression);
  if (!context.moveNext()) {
    throw new FormatException(
        'Empty regular expression', pattern.regularExpression);
  }
  final expression = parseUnknown(context, expectGroupEnd: false);
  assert(context.type == null);

  return new Root(expression, pattern);
}

Literal parseLiteral(TokenIterator context) {
  assert(context.type == TokenType.literal);
  final char = context.current;
  return new Literal(char, parseRepetiton(context..moveNext()));
}

Dot parseDot(TokenIterator context) {
  assert(context.type == TokenType.dot);
  return new Dot(parseRepetiton(context..moveNext()));
}

/// If the current token is a repetition, returns the according repetition
/// constant and advances the token iterator. Else, returns [Repetition.one].
Repetition parseRepetiton(TokenIterator context) {
  if (context.type != TokenType.repetition) {
    return Repetition.one;
  }
  final char = context.current;
  context.moveNext();
  switch (char) {
    case $plus:
      return Repetition.oneOrMore;
    case $question:
      return Repetition.zeroOrOne;
    case $asterisk:
      return Repetition.zeroOrMore;
    default:
      throw new UnimplementedError('This case is unreachable');
  }
}

/// Parses an unknown sequence of expressions until [context] is exhausted.
/// Creates [Sequence]s and [Alternation]s as needed, or returns a [State] if
/// only a single state pattern was found.
///
/// If [expectGroupEnd] is `true`, stops parsing when reaching the first
/// [TokenType.groupEnd]. Else, throws a [FormatException] when finding that
/// character.
Expression parseUnknown(TokenIterator context,
    {@required bool expectGroupEnd}) {
  assert(context.type != null);

  final alternatives = <Expression>[];
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
        alternatives.add(new Sequence(sequence));
        break;
    }
    sequence.clear();
  }

  loop:
  while (context.type != null) {
    switch (context.type) {
      case TokenType.literal:
        sequence.add(parseLiteral(context));
        break;
      case TokenType.dot:
        sequence.add(parseDot(context));
        break;
      case TokenType.repetition:
        context.error('Unescaped repetition character');
        break;
      case TokenType.alternation:
        nextAlternative();
        context.moveNext();
        break;
      case TokenType.groupStart:
        sequence.add(parseGroup(context));
        break;
      case TokenType.groupEnd:
        if (!expectGroupEnd) {
          context.error('Unbalanced `)`');
        }
        break loop;
      case TokenType.characterSetStart:
        sequence.add(parseCharacterSet(context));
        break;
      case TokenType.characterSetEnd:
        context.error('Unbalanced `]`');
        break;
      default:
        throw new UnimplementedError('This case is unreachable');
    }
  }
  nextAlternative();

  return alternatives.length == 1
      ? alternatives.first
      : new Alternation(alternatives);
}

Expression parseGroup(TokenIterator context) {
  assert(context.type == TokenType.groupStart);

  final startIndex = context.index;
  context.moveNext(onEndOfString: 'Unclosed `(`');

  final result = parseUnknown(context, expectGroupEnd: true);

  if (context.type != TokenType.groupEnd) {
    context.error('Unclosed `(`', startIndex);
  }
  context.moveNext();

  return result..repetition |= parseRepetiton(context);
}

CharacterSet parseCharacterSet(TokenIterator context) {
  assert(context.type == TokenType.characterSetStart);
  context.insideCharacterSet = true;

  final startIndex = context.index;
  context.moveNext(onEndOfString: 'Unclosed `[`');

  final negated = context.type == TokenType.setNegation;
  if (negated) {
    context.moveNext();
  }

  final runes = <Range>[];
  loop:
  while (context.type != null) {
    switch (context.type) {
      case TokenType.literal:
        final lowerBound = context.current;
        context.moveNext();
        if (context.type != TokenType.rangeSeparator) {
          runes.add(new Range.single(lowerBound));
          break;
        }
        context.moveNext();
        // ignore: invariant_booleans
        if (context.type == null) {
          break loop;
        } else if (context.type != TokenType.literal) {
          continue unescapedSpecialCharacter;
        }
        runes.add(new Range(lowerBound, context.current));
        context.moveNext();
        break;
      unescapedSpecialCharacter:
      case TokenType.characterSetStart:
      case TokenType.rangeSeparator:
      case TokenType.setNegation:
        context.error(
            '`${new String.fromCharCode(context.current)}` must be escaped in '
            'character sets, even if it is the first or last character');
        break;
      case TokenType.characterSetEnd:
        break loop;
      default:
        throw new UnimplementedError('This case is unreachable');
    }
  }

  if (context.type != TokenType.characterSetEnd) {
    context.error('Unclosed `[`', startIndex);
  }
  context
    ..insideCharacterSet = false
    ..moveNext();

  return new CharacterSet(runes, negated)..repetition = parseRepetiton(context);
}
