import 'package:regular_scanner/regular_scanner.dart';

const usd = Regex(r'$[0-9]+ USD');
const cad = Regex(r'$[0-9]+ CAD');
const eur = Regex(r'[0-9]+€');
const gbp = Regex(r'£[0-9]+');
final scanner = Scanner.unambiguous([usd, cad, eur, gbp]);

String detectCurrency(String userInput) {
  final match = scanner.matchAsPrefix(userInput);
  if (match == null || match.end != userInput.length) {
    throw FormatException('Unsupported format');
  }
  switch (match.regex) {
    case usd:
      return 'USD';
    case cad:
      return 'CAD';
    case eur:
      return 'EUR';
    case gbp:
      return 'GBP';
    default:
      throw UnimplementedError('This case should be unreachable.');
  }
}

void main() {
  for (final payment in [
    '5€',
    r'$100 USD',
    '£20',
  ]) {
    print('Payment `$payment` used ${detectCurrency(payment)}');
  }
}
