import 'package:charcode/ascii.dart';
import 'package:regular_scanner/src/range.dart';
import 'package:regular_scanner/src/regex/ast.dart';
import 'package:regular_scanner/src/regex/lexer.dart';
import 'package:regular_scanner/src/regex/parser.dart';
import 'package:test/test.dart';

/// Expects that `callback` throws a [FormatException] containing [offset] and
/// [message].
void expectFormatException(
    void Function() callback, int offset, String message) {
  try {
    callback();
  } on FormatException catch (e) {
    expect(e.offset, offset);
    expect(e.message, message);
    return;
  }
  fail("Was expected to throw '$message' at $offset, but returned normally");
}

void main() {
  group('`parseUnknown()`', () {
    TokenIterator scan(String regex) => TokenIterator(regex)..moveNext();

    test('defers to literal, dot, group, character set parsing functions', () {
      final result = parseUnknown(scan('a.(b)[c]')) as Sequence;
      expect(result.children[0], TypeMatcher<Literal>());
      expect(result.children[1], TypeMatcher<Wildcard>());
      expect(result.children[2], TypeMatcher<Group>());
      expect(result.children[3], TypeMatcher<CharacterSet>());
    });

    test('creates alternation only when needed', () {
      final result = parseUnknown(scan('abc')) as Sequence;
      expect(result.children[0], TypeMatcher<Literal>());
      expect(result.children[1], TypeMatcher<Literal>());
      expect(result.children[2], TypeMatcher<Literal>());
    });

    test('creates groups only when needed', () {
      final result = parseUnknown(scan('a|bc|d')) as Alternation;
      expect(result.children[0], TypeMatcher<Literal>());
      expect(result.children[1], TypeMatcher<Sequence>());
      expect(result.children[2], TypeMatcher<Literal>());
    });

    test('throws on other token types', () {
      expectFormatException(() => parseUnknown(scan('xx++')), 3,
          'Unescaped repetition character');
      expectFormatException(() => parseUnknown(scan('ab|*')), 3,
          'Unescaped repetition character');
      expectFormatException(() => parseUnknown(scan('?...')), 0,
          'Unescaped repetition character');
      expectFormatException(() => parseUnknown(scan(']')), 0, 'Unbalanced `]`');
    });

    test('throws on empty alternation', () {
      expectFormatException(
          () => parseUnknown(scan('a||b')), 2, 'Empty alternative');
      expectFormatException(
          () => parseUnknown(scan('|a')), 0, 'Empty alternative');
    });

    test('stops at first `)`', () {
      final it = scan('x|yz)def');
      final result = parseUnknown(it) as Alternation;
      expect(it.index, 4);
      expect(result.children.length, 2);
    });
  });

  group('`parseCharacterSet()`', () {
    TokenIterator scan(String regex) => TokenIterator(regex)
      ..moveNext()
      ..insideCharacterSet = true;

    final unescapedSpecialCharacterError = r'The special characters `[]^-\` '
        'must always be escaped inside character groups';

    test('parses single characters and ranges', () {
      final set = parseCharacterSet(scan('[ag-hf4-6]'));
      expect(set.negated, isFalse);
      expect(set.codePoints, const [
        Range.single($a),
        Range($g, $h),
        Range.single($f),
        Range($4, $6)
      ]);
    });

    test('recognizes negated sets', () {
      final set = parseCharacterSet(scan(r'[^A-MZ]'));
      expect(set.negated, isTrue);
      expect(set.codePoints, const [Range($A, $M), Range.single($Z)]);
    });

    test(
        'throws on invalid ranges',
        () => expectFormatException(() => parseCharacterSet(scan('[Z-A]')), 1,
            'Ranges must be specified from low to high'));

    test('throws on unescaped caret', () {
      expectFormatException(() => parseCharacterSet(scan('[a^b]')), 2,
          unescapedSpecialCharacterError);
      expectFormatException(() => parseCharacterSet(scan(r'[+$^]')), 3,
          unescapedSpecialCharacterError);
    });

    test('throws on unmatched range separator', () {
      expectFormatException(
          () => parseCharacterSet(scan('[56-]')), 3, 'Incomplete range');
      expectFormatException(() => parseCharacterSet(scan('[-abc]')), 1,
          unescapedSpecialCharacterError);
      expectFormatException(() => parseCharacterSet(scan('[-]')), 1,
          unescapedSpecialCharacterError);
    });

    test('throws on missing `]`', () {
      expectFormatException(
          () => parseCharacterSet(scan('[abc')), 0, 'Unclosed `[`');
      expectFormatException(
          () => parseCharacterSet(scan('[k-')), 0, 'Unclosed `[`');
      expectFormatException(
          () => parseCharacterSet(scan('[')), 0, 'Unclosed `[`');
    });
  });
}
