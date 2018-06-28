import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'regular_scanner.dart';

const String libraryUri = 'package:regular_scanner/regular_scanner.dart';

/// The [BuilderFactory] that is specified in `build.yaml`.
Builder scannerBuilder(BuilderOptions options) =>
    new PartBuilder(const [const ScannerGenerator()]);

class ScannerGenerator extends GeneratorForAnnotation<InjectScanner> {
  const ScannerGenerator();

  @override
  FutureOr<String> generateForAnnotatedElement(final Element element,
      final ConstantReader annotation, final BuildStep buildStep) {
    if (element is! TopLevelVariableElement) {
      log.warning('The @InjectScanner annotation is only '
          'supported on top level variables');
      return null;
    }
    final variable = element as TopLevelVariableElement;

    final prefix = element.library.imports
        .firstWhere((import) => import.uri == libraryUri)
        .prefix;
    final prefixString = prefix != null ? '${prefix.name}.' : '';

    final patterns = annotation.objectValue.getField('patterns')?.toListValue();
    if (patterns == null) {
      log.warning('The @InjectScanner is missing the parameter `patterns`.');
      return null;
    } else if (patterns.isEmpty) {
      log.warning('The pattern list of @InjectScanner is empty');
      return null;
    }
    return '''
const _\$${variable.name} = const ${prefixString}Scanner([

]);
''';
  }
}
