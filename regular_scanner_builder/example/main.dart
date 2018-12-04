import 'package:regular_scanner/built_scanner.dart';

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
    for (final match in scanner.allMatches(input)) {
      if (match.regex != whitespace) {
        print('- ${match.capture} is a ${match.regex.name} number');
      }
    }
  }
}
