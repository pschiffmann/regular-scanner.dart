import 'package:regular_scanner/regular_scanner.dart' as rs;

part 'main.g.dart';

final source = '''
''';

const NamedPattern whitespace = const NamedPattern('[ \t\r\n]+', 'whitespace');

@rs.InjectScanner([
  const NamedPattern('0b[01]+', 'binary'),
  const NamedPattern('0[0-7]+', 'octal', precedence: 1),
  const NamedPattern('[0-9]+', 'decimal', precedence: 0),
  const NamedPattern('0x[0-9A-Fa-f]+', 'hexadecimal'),
  whitespace
])
const rs.Scanner<NamedPattern> scanner = _$scanner;

class NamedPattern extends rs.Pattern {
  const NamedPattern(String regularExpression, this.name, {int precedence: 0})
      : super(regularExpression, precedence: precedence);

  final String name;
}

void main() {
  final it = source.runes.iterator..moveNext();
  while (it.current != null) {
    final start = it.rawIndex;
    final match = scanner.match(it);
    if (match == null) {
      print('Unexpected character ${it.current}');
    } else if (match.pattern != whitespace) {
      print('${source.substring(start, match.length)} '
          'is a ${match.pattern.name} number');
    }
  }
}
