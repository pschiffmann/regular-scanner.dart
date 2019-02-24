import 'package:regular_scanner/src/regexp/unicode.dart';
import 'package:test/test.dart';

void main() {
  group('isUnicodeScalarValue()', () {
    test('recognizes BMP code points',
        () => expect(isUnicodeScalarValue('A'.runes.single), isTrue));

    test('recognizes supplementary plane code points',
        () => expect(isUnicodeScalarValue('😀'.runes.single), isTrue));

    test('rejects non-code points', () {
      expect(isUnicodeScalarValue(-1), isFalse);
      expect(isUnicodeScalarValue(0x110000), isFalse);
    });

    test('rejects surrogate code points', () {
      expect(isUnicodeScalarValue(0xD800), isFalse);
      expect(isUnicodeScalarValue(0xDC00), isFalse);
      expect(isUnicodeScalarValue(0xDFFF), isFalse);
    });
  });

  test('decodeSurrogatePair() resolves the correct code point', () {
    expect(decodeSurrogatePair('😀'.codeUnitAt(0), '😀'.codeUnitAt(1)),
        '😀'.runes.single);
    expect(decodeSurrogatePair('𝄞'.codeUnitAt(0), '𝄞'.codeUnitAt(1)),
        '𝄞'.runes.single);
  });
}
