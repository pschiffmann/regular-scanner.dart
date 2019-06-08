import 'dart:html';

import 'package:regular_scanner/regular_scanner.dart';

// https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent/keyCode
const up = '\x26';
const down = '\x28';
const left = '\x25';
const right = '\x27';
const a = '\x41';
const b = '\x42';

/// https://en.wikipedia.org/wiki/Konami_Code: `↑ ↑ ↓ ↓ ← → ← → B A`
///
/// Prefixed with `.*` to skip over other key events.
final konamiCode = Scanner.unambiguous(
    [Regex('.*$up$up\\$down\\$down$left$right$left$right$b$a')]);

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
