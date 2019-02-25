import 'package:regular_scanner/regular_scanner.dart';
import 'package:regular_scanner/state_machine.dart';

Iterable<ScannerMatch<T>> allMatchesAt<T extends Regex>(
  Scanner<T, StateMachine<T>> scanner,
  String string, [
  int start = 0,
]) sync* {
  final sm = scanner.stateMachine();
  final runes = RuneIterator.at(string, start);

  while (runes.moveNext()) {
    sm.moveNext(runes.current);
    if (sm.inErrorState) break;
    if (sm.accept != null) {
      yield ScannerMatch(scanner, sm.accept, string, start,
          runes.rawIndex + runes.currentSize);
    }
  }
}

void main() {
  const dec = Regex('[0-9]+', precedence: 1);
  const hex = Regex('[0-9A-F]+');
  final scanner = Scanner.unambiguous([dec, hex]);
  final exampleInput = '6578616D706C65';
  print('Matching $exampleInput against $dec, $hex');

  for (final match in allMatchesAt(scanner, exampleInput)) {
    print('${match.regex} matches the substring ${match.capture}');
  }
}
