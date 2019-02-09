import 'package:regular_scanner/regular_scanner.dart';

const binary = Regex('0b[01]+');
const octal = Regex('0[0-7]+', precedence: 1);
const decimal = Regex('[0-9]+', precedence: 0);
const hexadecimal = Regex('0x[0-9A-Fa-f]+');

final scanner = Scanner.unambiguous([binary, octal, decimal, hexadecimal]);

const exampleInput = ['0b01010010', '0145', '103', '0x65', 'x'];

void main([List<String> args]) {
  if (args.isEmpty) args = exampleInput;

  for (final input in args) {
    final match = scanner.matchAsPrefix(input);
    if (match == null) {
      print("Input doesn't match");
      continue;
    }
    switch (match.regex) {
      case binary:
        final parsed = int.parse(input.substring('0b'.length), radix: 2);
        print('$input (binary) = $parsed (decimal)');
        break;
      case octal:
        final parsed = int.parse(input, radix: 8);
        print('$input (octal) = $parsed (decimal)');
        break;
      case decimal:
        print('$input is a decimal number');
        break;
      case hexadecimal:
        final parsed = int.parse(input.substring('0x'.length), radix: 16);
        print('$input (hex) = $parsed (decimal)');
        break;
    }
  }
}
