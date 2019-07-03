// To try out this example:
//  1. `pub global activate webdev`
//  2. `pub global run webdev serve example/`
//  3. Visit http://localhost/konami_code.html

import 'dart:html';

import 'package:regular_scanner/regular_scanner.dart';

// https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent/keyCode
const up = r'\u{0026}';
const down = r'\u{0028}';
const left = r'\u{0025}';
const right = r'\u{0027}';
const a = r'\u{0041}';
const b = r'\u{0042}';

/// https://en.wikipedia.org/wiki/Konami_Code: `↑ ↑ ↓ ↓ ← → ← → B A`
///
/// Prefixed with `.*` to skip over other key events.
final konamiCode = Scanner.unambiguous(
    [Regex('.*$up$up$down$down$left$right$left$right$b$a')]);

void main() {
  final stateMachine = konamiCode.stateMachine();
  document.onKeyDown.listen((event) {
    stateMachine.moveNext(event.keyCode);
    if (stateMachine.accept != null) {
      window.alert('Konami code recognized');
      stateMachine.reset();
    } else if (stateMachine.inErrorState) {
      window.console.error('How did we get here?');
    }
  });
}
