regular_scanner
===============

A `Scanner` class that matches an input string against multiple regular expressions.

```dart
@InjectScanner([
  const Pattern('0[0-7]+', 'octal', precedence: 1),
  const Pattern('[0-9]+', 'decimal', precedence: 0),
  const Pattern('0x[0-9A-Fa-f]+', 'hexadecimal')
])
const Scanner scanner = _$scanner;

void main(String[] args) {
  for (final input in args) {
    final match = scanner.match(input.codeUnits.iterator);
    print(match != null ? '$input matched ${match.pattern}' : 'No match');
  }
}
```

Performance
-----------

Since Dart native `RegExp`s are implementated with a backtracking algorithm, they run in exponential time in the worst case.
Even if expressions don't encounter this worst case (which is admittedly unlikely), matching a string against multiple expressions still requires to iterate over them one by one, resulting in a quadratic run time (`input.length` × number of patterns) even in the best case.

In contrast, this package compiles all regular expressions of a scanner into a single [DFA][dfa].
Matching runs in linear time of the input string, independently of the number of expressions.

If the patterns are compile-time constant – like in the example above – the DFA can be constructed at compile (or rather [build][build]) time.

ambiguity warnings
------------------

Since the DFA knows all possible paths through the patterns, it is possible to detect ambiguities.
When multiple patterns match the same input, the `Scanner` constructor throws an exception.
To resolve this problem, specify which pattern should "win" by assigning it a higher _precedence_ value.

Syntax
------

Dart regular expressions are more than [regular][regular language].
This makes them more powerful, but also more expensive to execute.
Some of their features, like lookahead/lookbehind assertions and capturing groups, cannot be expressed by a DFA.
If you need that extra power, you should use native `RegExp`s; this package only supports the syntax specified here.
Differences in behaviour between this package and `RegExp` are _emphasized_.

### general escape sequences

An escape sequence is a character sequence that starts with `\`.
If you need to match a literal `\`, precede it with `\`, like so: `\\`.
These escape sequences are recognized in both contexts.

 * `\t`, `\r`, `\n`, `\v`, `\f`, `\0` match the ASCII control characters tab, carriage return, linefeed, vertical tab, form-feed and NUL, respectively.
 * `\u{hhhh}` or `\u{hhhhh}` match the character with the Unicode value U+`hhhh` or U+`hhhhh` (hexadecimal digits).

_If an unrecognized escape sequence is encountered, an exception is thrown._

### default context

Outside of a character set, the following characters have a special meaning:

 * `.` matches any single character, _including newlines._
 * `[` and `]` mark the beginning and end of a character set.
 * `+`, `*` and `?` are repetition specifiers.
   `*` and `?` make the previous matcher optional; `+` and `*` make it repeatable.
 * `()` can be used to apply a repetition specifier to a sequence of matchers.
 * `|` indicates alternation between the left and right matchers.

If you need to match any of these characters literally, you need to escape them with `\`.

Furthermore, there exist several aliases for commonly used character sets.

 * `\d` matches `[0-9]`.
 * `\w` matches `[A-Za-z0-9_]`.
 * `\s` matches `[ \f\n\r\t\v\u{00a0}\u{1680}\u{2000}-\u{200a}\u{2028}\u{2029}\u{202f}\u{205f}\u{3000}\u{feff}]`.

Each alias also exists in a negated (uppercase) variant that matches iff their lowercase counterpart doesn't match.
For example, `\D` is equivalent to `[^0-9]`.

Any other character matches itself.

### character sets

A character set consumes a single character from the input string and matches any character inside the square brackets.
You can specify character ranges with `-`:
`[ace-g]` matches any of the characters `a`, `c`, `e`, `f` and `g`.
A leading `^` inside the brackets indicates negation and causes the expression to match any character except those enclosed in the square brackets.

_Inside a character set, `[]^-` must always be `\`-escaped, even if they appear at the very first or last position in the set._

Usage
-----

### Importing the library

The `regular_scanner.dart` library shadows the `Pattern` class from `dart:core`.
If you need both, import either of them with a prefix:

```dart
import 'package:regular_scanner/regular_scanner.dart' as rs;
// or:
import 'dart:core' hide Pattern;
import 'dart:core' as c show Pattern;
```

### Handling a match

Patterns are greedy.
If an input matches multiple patterns, the scanner will always choose the longest match.
To find out which pattern matched an input, use the `pattern` property of the match result.

You can either compare with that value directly:

```dart
const word = const Pattern('[A-Za-z]+');
const number = const Pattern('[0-9]+');

@InjectScanner([word, number])
const Scanner scanner = _$scanner;

void main(String[] args) {
  final match = scanner.match(input.first);
  switch(match.pattern) {
    case word:
      print('is word');
      break;
    case number:
      print('is number');
      break;
  }
}
```

Or you can `extend` the `Pattern` class to attach custom properties or methods to the result:

```dart
class NamedPattern extends Pattern {
  const NamedPattern(String regularExpression, this.name, {int precedence: 0})
      : super(regularExpression, precedence: precedence);

  final String name;
}

const word = const NamedPattern('[A-Za-z]+', 'word');
const number = const NamedPattern('[0-9]+', 'number');

@InjectScanner([word, number])
const Scanner<NamedPattern> scanner = _$scanner;

void main(String[] args) {
  final match = scanner.match(input.first);
  print('is ${match.pattern.name}');
}
```

### Instantiating a scanner

If you use the `@InjectScanner` annotation, whenever you modify its patterns you need to run code generation. Code generation is only supported for top-level variables.

```shell
pub run build_runner build
```

If you do not know the patterns at compile time, you can also construct a `Scanner` at runtime by passing the `Patterns` to the constructor directly.

Benchmarks
----------

**TODO**

_Right now, the scanner is table driven. I might try to generate the scanner as Dart methods and compare performance._

[dfa]: https://en.wikipedia.org/wiki/Deterministic_finite_automaton
[build]: https://pub.dartlang.org/packages/build_runner
[regular language]: https://en.wikipedia.org/wiki/Regular_language
