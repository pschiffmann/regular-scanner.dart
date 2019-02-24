library regular_scanner.built_scanner;

import 'package:regular_scanner/regular_scanner.dart';

export 'regular_scanner.dart';
export 'src/regex/state_machine_scanner.dart' show BuiltScanner;
export 'src/state_machine/dfa.dart';

/// This annotation marks a `const` variable as an injection point for a
/// [Scanner], and specifies which [Regex]es that scanner matches.
class InjectScanner {
  const InjectScanner(this.regexes);

  final List<Regex> regexes;
}
