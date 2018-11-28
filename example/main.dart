import 'package:regular_scanner/regular_scanner.dart';

part 'main.g.dart';

const whitespace = NamedRegex('[ \t\r\n]+', 'whitespace');

@InjectScanner([
  NamedRegex('0b[01]+', 'binary'),
  NamedRegex('0[0-7]+', 'octal', precedence: 1),
  NamedRegex('[0-9]+', 'decimal', precedence: 0),
  NamedRegex('0x[0-9A-Fa-f]+', 'hexadecimal'),
  whitespace
])
const Scanner<NamedRegex> scanner = _$scanner;

class NamedRegex extends Regex {
  const NamedRegex(String regularExpression, this.name, {int precedence = 0})
      : super(regularExpression, precedence: precedence);

  final String name;
}

void main(List<String> args) {
  if (args.isEmpty) {
    print('Pass command line arguments to this program to check whether they '
        'match a regex');
    return;
  }

  for (final input in args) {
    print('Matching $input:');
    final it = input.runes.iterator..moveNext();
    while (it.current != null) {
      final start = it.rawIndex;
      final match = scanner.match(it, rewind: true);
      if (match == null) {
        print('- Match failed at character ${it.current}');
      } else if (match.regex != whitespace) {
        print('- ${input.substring(start, start + match.length)} '
            'matches regex ${match.regex.name}');
      }
    }
  }
}
