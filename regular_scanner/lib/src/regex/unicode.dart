import '../range.dart';

/// The [Unicode code point](http://unicode.org/glossary/#code_point) range.
const unicodeRange = Range(0, 0x10FFFF);

/// The [surrogate code point]
/// (http://unicode.org/glossary/#surrogate_code_point) range.
const surrogateRange = Range(0xD800, 0xDFFF);

/// Returns whether [codePoint] is a [Unicode scalar value]
/// (http://unicode.org/glossary/#unicode_scalar_value).
bool isUnicodeScalarValue(int codePoint) =>
    unicodeRange.contains(codePoint) && !surrogateRange.contains(codePoint);

/// Combines a lead surrogate and a trail surrogate into a Unicode scalar value.
///
/// Algorithm copied from: https://www.unicode.org/faq/utf_bom.html#utf16-4
int decodeSurrogatePair(int leadSurrogate, int trailSurrogate) {
  const leadSurrogateRange = Range(0xD800, 0xDBFF);
  const trailSurrogateRange = Range(0xDC00, 0xDFFF);
  assert(leadSurrogateRange.contains(leadSurrogate));
  assert(trailSurrogateRange.contains(trailSurrogate));

  const surrogateOffset = 0x10000 - (0xD800 << 10) - 0xDC00;
  return (leadSurrogate << 10) + trailSurrogate + surrogateOffset;
}
