library regular_scanner.unicode;

import '../range.dart';

const unicodeRange = Range(0, 0x10FFFF);
const permanentlyUnassigned = Range(0xD800, 0xDFFF);

bool isValidCodePoint(int codePoint) =>
    unicodeRange.contains(codePoint) &&
    !permanentlyUnassigned.contains(codePoint);

bool isLeadSurrogate(int codeUnit) =>
    const Range(0xD800, 0xDBFF).contains(codeUnit);

bool isTrailSurrogate(int codeUnit) =>
    const Range(0xDC00, 0xDFFF).contains(codeUnit);

/// Algorithm copied from: https://www.unicode.org/faq/utf_bom.html#utf16-4
int decodeSurrogatePair(int leadSurrogate, int trailSurrogate) {
  assert(isLeadSurrogate(leadSurrogate));
  assert(isTrailSurrogate(trailSurrogate));

  const surrogateOffset = 0x10000 - (0xD800 << 10) - 0xDC00;
  return (leadSurrogate << 10) + trailSurrogate + surrogateOffset;
}
