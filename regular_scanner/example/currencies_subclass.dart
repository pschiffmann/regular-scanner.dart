import 'package:regular_scanner/regular_scanner.dart';

class CurrencyPattern extends Regex {
  CurrencyPattern(String regex, this.currency) : super(regex);
  final String currency;
}

final scanner = Scanner.unambiguous([
  CurrencyPattern(r'$[0-9]+ USD', 'USD'),
  CurrencyPattern(r'$[0-9]+ CAD', 'CAD'),
  CurrencyPattern(r'[0-9]+€', 'EUR'),
  CurrencyPattern(r'£[0-9]+', 'GBP'),
]);

String detectCurrency(String userInput) {
  final match = scanner.matchAsPrefix(userInput);
  if (match == null || match.end != userInput.length) {
    throw FormatException('Unsupported format');
  }
  return match.regex.currency;
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
