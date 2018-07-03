import 'package:regular_scanner/regular_scanner.dart' as rs;

class NamedPattern extends rs.Pattern {
  const NamedPattern(String pattern, this.name, {int precedence})
      : super(pattern, precedence: precedence);

  final String name;

  @override
  String toString() => '$name ::= ${super.toString()}';
}

void main() {
  final patterns = [
    const NamedPattern(r'0b[01]+', 'binary'),
    const NamedPattern(r'0[0-7]+', 'octal', precedence: 1),
    const NamedPattern(r'[0-9]+', 'decimal', precedence: 0),
    const NamedPattern(r'0x[0-9A-Fa-f]+', 'hexadecimal'),
    const NamedPattern(r'[ \t\r\n]+', 'whitespace')
  ];
  final scanner = new rs.Scanner(patterns);
  for (var i = 0; i < scanner.states.length; i++) {
    final state = scanner.states[i];
    print('$i ${state.transitions}, '
        'default=${state.defaultTransition}, accept=${state.accept}');
  }
  print(scanner.match('0123'.codeUnits.iterator));
}
