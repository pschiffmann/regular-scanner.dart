library regular_scanner.builder;

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:regular_scanner/built_scanner.dart';
import 'package:source_gen/source_gen.dart';

/// The names of all top level elements (classes and variables) generated by
/// this builder start with `_$`.
const String generatedNamesPrefix = r'_$';

/// The [LibraryElement] that represents the
/// `package:regular_scanner/regular_scanner.dart` library.
LibraryElement get regularScannerLibrary =>
    Zone.current[#regularScannerLibrary];

/// The [LibraryElement] that represents the library that is currently getting
/// processed.
LibraryElement get hostLibrary => Zone.current[#hostLibrary];

/// The [BuilderFactory] that is specified in `build.yaml`.
Builder scannerBuilder(BuilderOptions options) =>
    SharedPartBuilder(const [TableDrivenScannerGenerator()], 'regular_scanner');

/// Returns the local name of [cls], as visible in [hostLibrary].
///
/// For example, if [hostLibrary] contains the import directive
/// ```dart
/// import 'package:regular_scanner/regular_scanner.dart' as rs show Scanner;
/// ```
/// then for the [cls] [Scanner], this function will return the string
/// `'rs.Scanner'`.
///
/// Throws an [InvalidGenerationSourceError] if [cls] is not visible in
/// [hostLibrary].
String resolveLocalName(ClassElement cls) {
  final className = cls.name;
  if (hostLibrary.getType(className) == cls) {
    return className;
  }
  for (final import in hostLibrary.imports) {
    final localName =
        import.prefix == null ? className : '${import.prefix.name}.$className';
    if (import.namespace.get(localName) == cls) {
      return localName;
    }
  }
  throw InvalidGenerationSourceError(
      '${cls.name} is not visible in the current source file',
      todo: "Import library `${cls.library}`, and don't hide this class");
}

/// This generator reads the [Regex]es from an [InjectScanner] annotation and
/// generates the Dart code required to instantiate a corresponding [Scanner].
abstract class ScannerGenerator extends GeneratorForAnnotation<InjectScanner> {
  const ScannerGenerator();

  @override
  FutureOr<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    final variable = validateAnnotatedElement(element);

    return runZoned(() {
      final regexes =
          resolveInjectScannerArguments(variable, annotation.objectValue);
      final regexType = resolveRegexType(variable);

      return generateScanner(
          Scanner<RegexWithInitializer>.deterministic(regexes),
          variable.name,
          regexType);
    }, zoneValues: {
      #regularScannerLibrary: annotation.objectValue.type.element.library,
      #hostLibrary: variable.library
    });
  }

  /// This method is called from [generateForAnnotatedElement]   generates the
  /// actual code, once the annotation is resolved and validated.
  ///
  /// [scanner] contains a scanner that was built from the [InjectScanner]
  /// annotation values. [scannerVariableName] contains the name of the
  /// annotated variable. [regexType] contains the result of
  /// [resolveRegexType].
  String generateScanner(TableDrivenScanner<RegexWithInitializer> scanner,
      String scannerVariableName, ClassElement regexType);
}

/// Ensures that the element annotated with [InjectScanner] is a valid target
/// for the annotation.
///
/// Throws an [InvalidGenerationSourceError] if
///   * the annotated element is not a [TopLevelVariableElement],
///   * the annotated variable is not declared `const`, or
///   * the annotated variable is not initialized with a variable named
///     `'_$' + variableName`.
TopLevelVariableElement validateAnnotatedElement(Element element) {
  if (element is! TopLevelVariableElement) {
    throw InvalidGenerationSourceError(
        '@InjectScanner must annotate a top level variable',
        element: element);
  }
  final TopLevelVariableElement variable = element;
  if (!variable.isConst) {
    throw InvalidGenerationSourceError(
        '@InjectScanner must annotate a `const` variable',
        element: variable);
  }
  final expectedInitializer = generatedNamesPrefix + variable.name;
  final initializer = variable.computeNode().initializer;
  if (!(initializer is Identifier && initializer.name == expectedInitializer)) {
    throw InvalidGenerationSourceError(
        'The injection point must be initialized to `$expectedInitializer`, '
        ' the generated variable that holds the scanner',
        element: variable);
  }
  return variable;
}

/// Extracts the initializer `const` expressions of the individual [Regex]es
/// in the [InjectScanner] annotation from the AST of [variable].
List<RegexWithInitializer> resolveInjectScannerArguments(
    TopLevelVariableElement variable, DartObject injectScanner) {
  final regexes = injectScanner.getField('regexes')?.toListValue();
  if (regexes == null || regexes.isEmpty) {
    throw InvalidGenerationSourceError(
        'The @InjectScanner regex list must not be empty',
        element: variable);
  }

  final astNode = variable.computeNode();
  final metadata =
      (astNode.parent.parent as TopLevelVariableDeclaration).metadata;
  for (final annotation in metadata) {
    if (annotation.elementAnnotation.constantValue != injectScanner) {
      continue;
    }

    final initializerList = annotation.arguments.arguments.first;
    if (initializerList is! ListLiteral) {
      throw InvalidGenerationSourceError(
          'The regexes must be explicitly enumerated in the `@InjectScanner` '
          'annotation parameter',
          element: variable);
    }
    final initializers = (initializerList as ListLiteral).elements;

    final result = <RegexWithInitializer>[];
    for (var i = 0; i < initializers.length; i++) {
      final regex = ConstantReader(regexes[i]);
      result.add(RegexWithInitializer(
          regex.read('regularExpression').stringValue,
          regex.read('precedence').intValue,
          initializers[i].toSource()));
    }
    return result;
  }
  throw UnimplementedError(
      'Reaching this line means we skipped over the relevant annotation – '
      "that's a bug");
}

/// Returns the generic type argument of the generated [Scanner], or `null` if
/// the analyzed code doesn't specify a type.
ClassElement resolveRegexType(TopLevelVariableElement variable) {
  final variableType = variable.type;
  if (variableType == null) {
    return null;
  }
  if (variableType.element != regularScannerLibrary.getType('Scanner')) {
    throw InvalidGenerationSourceError(
        'The static type of the annotated variable must be Scanner',
        element: variable);
  }
  return (variableType as ParameterizedType).typeArguments.first.element;
}

/// An instance of this class represents a regex from an [InjectScanner]
/// annotation. It contains the [regularExpression] and [precedence] that are
/// needed for the scanner construction algorithm, and the information how to
/// reconstruct the initial annotation argument.
class RegexWithInitializer extends Regex {
  RegexWithInitializer(
      String regularExpression, int precedence, this.initializerExpression)
      : super(regularExpression, precedence: precedence);

  /// The exact string that is used in the parsed source code. This is either a
  /// constant constructor invocation, or a variable reference.
  final String initializerExpression;
}

/// Encodes the built scanner as a `const` [TableDrivenScanner].
class TableDrivenScannerGenerator extends ScannerGenerator {
  const TableDrivenScannerGenerator();

  @override
  String generateScanner(TableDrivenScanner<RegexWithInitializer> scanner,
      String scannerVariableName, ClassElement regexType) {
    final stateTypeName = resolveLocalName(
            regularScannerLibrary.exportNamespace.get('State')),
        transitionTypeName = resolveLocalName(
            regularScannerLibrary.exportNamespace.get('Transition'));

    final result = StringBuffer()
      ..write(r'const ')
      ..write(generatedNamesPrefix)
      ..write(scannerVariableName)
      ..write(' = ')
      ..write(resolveLocalName(
          regularScannerLibrary.exportNamespace.get('Scanner')));
    if (regexType != null) {
      result..write('<')..write(resolveLocalName(regexType))..write('>');
    }
    result.writeln('.withParseTable([], [');
    for (final state in scanner.states) {
      result
        ..write(stateTypeName)
        ..writeln('([');
      for (final transition in state.transitions) {
        result
          ..write(transitionTypeName)
          ..write('(')
          ..write(transition.min)
          ..write(', ')
          ..write(transition.max)
          ..write(', ')
          ..write(transition.successor)
          ..writeln('),');
      }
      result
        ..write('], ')
        ..write('defaultTransition: ')
        ..write(state.defaultTransition);
      if (state.accept != null) {
        result
          ..write(', ')
          ..write('accept: ')
          ..write(state.accept.initializerExpression);
      }
      result.writeln('),');
    }
    return (result..writeln(']);')).toString();
  }
}
