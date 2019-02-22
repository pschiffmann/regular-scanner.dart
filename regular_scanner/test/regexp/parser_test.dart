import 'package:charcode/ascii.dart';
import 'package:regular_scanner/src/range.dart';
import 'package:regular_scanner/src/regexp/lexer.dart';
import 'package:regular_scanner/src/regexp/parser.dart';
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
