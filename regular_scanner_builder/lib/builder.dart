import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/builder.dart';

/// The [BuilderFactory] that is specified in `build.yaml`.
Builder scannerBuilder(BuilderOptions options) {
  if (options.config.isNotEmpty) {
    log.warning('Ignoring unused config options: ${options.config.keys}');
  }
  return SharedPartBuilder(
      const [StateMachineScannerGenerator()], 'regular_scanner');
}
