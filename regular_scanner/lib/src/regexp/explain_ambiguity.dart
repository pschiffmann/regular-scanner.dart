import 'dart:math';

import 'package:charcode/ascii.dart';

import '../../regular_scanner.dart';
import '../../state_machine.dart';
import 'unicode.dart';

/// Returns the element in [regexes] with the highest [Regex.precedence], or
/// `null` if [regexes] is empty. Throws an [AmbiguousRegexException] if
/// there is no single highest precedence regex.
T highestPrecedenceRegex<T extends Regex>(Set<T> regexes) {
  if (regexes.isEmpty) return null;

  final highestPrecedence = [regexes.first];
  for (final regex in regexes.skip(1)) {
    if (highestPrecedence.first.precedence == regex.precedence) {
      highestPrecedence.add(regex);
    } else if (regex.precedence > highestPrecedence.first.precedence) {
      highestPrecedence
        ..clear()
        ..add(regex);
    }
  }

  return highestPrecedence.length == 1
      ? highestPrecedence.first
      : throw AmbiguousRegexException(highestPrecedence);
}

class AmbiguousRegexException<T extends Regex>
    extends AmbiguousInputException<T> {
  AmbiguousRegexException(Iterable<T> collisions) : super(collisions);

  @override
  String toString() =>
      'The patterns ${collisions.join(", ")} all match the ' +
      (states.isEmpty
          ? 'empty string'
          : 'string ${generateAmbiguousInput(states)}');
}

///
String generateAmbiguousInput(List<DState> states) {
  final buffer = StringBuffer();
  final path = Dfa.findShortestPath(states);
  var containsDoubleQuote = false;
  var containsSingleQuote = false;
  for (var i = 0; i < path.length - 1; i++) {
    final char = findTransitionTo(states[path[i]], path[i + 1]);
    buffer.write(char);
    if (char == '"') {
      containsDoubleQuote = true;
    } else if (char == "'") {
      containsSingleQuote = true;
    }
  }
  if (!containsDoubleQuote) return '"$buffer"';
  if (!containsSingleQuote) return "'$buffer'";
  return '`$buffer`';
}

String findTransitionTo(DState state, int successor) {
  String character;
  var quality = 6;

  void consider(Range range, int s) {
    if (successor != s) return;
    final candidate = selectBestCharacter(range);
    if (candidate.value < quality) {
      character = candidate.key;
      quality = candidate.value;
    }
  }

  var position = 0;
  for (final transition in state.transitions) {
    if (position < transition.min) {
      consider(Range(position, transition.min - 1), state.defaultTransition);
    }
    consider(transition, transition.successor);
    position = transition.max + 1;

    // [$del] was the last ASCII character. If we have already found a
    // transition, it will not improve from now on.
    if (quality == 1 || position >= $del && character != null) return character;
  }
  if (position < unicodeRange.max) {
    consider(Range(position, unicodeRange.max), state.defaultTransition);
  }
  return character;
}

/// Searches for a visible ASCII code point in [codePoints].
///
/// Returns a (string representation, quality) tuple. The quality can be used
/// to compare the results of different calls to this function against each
/// other (lower is better). The quality classes are:
///
///  1. Alphanumeric ASCII characters (A-Z, a-z, 0-9).
///  2. Remaining visible ASCII symbols (`!`-`~`).
///  3. ASCII space, rendered as `␣`.
///  4. ASCII control characters (U+0000-U+001F and U+007F), rendered with the
///     visible glyphs from http://www.unicode.org/charts/PDF/U2400.pdf.
///  5. Non-ASCII characters, rendered as `U+hhhhhh`.
MapEntry<String, int> selectBestCharacter(Range codePoints) {
  const alphanum = [Range($A, $Z), Range($a, $z), Range($0, $9)];
  const symbols = Range($exclamation, $tilde);
  const controlCharacters = Range($nul, $us);

  /// Finds the leftmost intersection of [chars] and [codePoints].
  int i(Range chars) => max(chars.min, codePoints.min);
  String s(int codePoint) => String.fromCharCode(codePoint);

  for (final chars in alphanum) {
    if (chars.intersects(codePoints)) return MapEntry(s(i(chars)), 1);
  }

  if (codePoints.intersects(symbols)) return MapEntry(s(i(symbols)), 2);

  if (codePoints.contains($space)) return const MapEntry('␣', 3);

  if (controlCharacters.intersects(codePoints)) {
    return MapEntry(s(0x2400 + i(controlCharacters)), 4);
  }
  if (controlCharacters.contains($del)) return const MapEntry('␡', 4);

  return MapEntry('U+${codePoints.min.toRadixString(16).padLeft(4, "0")}', 5);
}
