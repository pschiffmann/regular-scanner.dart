import 'dart:async';
import 'dart:core' hide Pattern;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:meta/meta.dart';
import 'package:regular_scanner/src/dfa.dart';
import 'package:source_gen/source_gen.dart';

import 'regular_scanner.dart';

const regularScannerLibraryUri = 'package:regular_scanner/regular_scanner.dart';
const generatedNamesPrefix = r'_$';

const isInjectScanner = const TypeChecker.fromRuntime(Pattern);

/// The [BuilderFactory] that is specified in `build.yaml`.
Builder scannerBuilder(BuilderOptions options) =>
    new PartBuilder([new TableDrivenScannerGenerator()],
        header: options.config['header'] as String);

/// This generator reads the [Pattern]s from an [InjectScanner] annotation and
/// generates the Dart code required to instantiate a [Scanner] for these
/// patterns.
abstract class ScannerGenerator extends GeneratorForAnnotation<InjectScanner> {
  const ScannerGenerator();

  @override
  FutureOr<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    validateAnnotatedElement(element);
    final variable = element as TopLevelVariableElement;

    final patterns = annotation.peek('patterns')?.listValue;
    if (patterns == null || patterns.isEmpty) {
      throw new InvalidGenerationSourceError(
          'The @InjectScanner pattern list must not be empty',
          element: element);
    }

    return generateScanner(
        patterns
            .map((pattern) => new PatternWithInitializer.fromAnnotation(
                new ConstantReader(pattern)))
            .toList(growable: false),
        scannerName: variable.name,
        patternTypeName: resolvePatternTypeName(variable),
        libraryPrefixes: resolvePrefixes(element.library));
  }

  /// This method generates the actual code, once the annotation is resolved and
  /// validated.
  ///
  /// [scannerName] contains the name of the variable that is annotated with
  /// [InjectScanner]. [patternTypeName] contains the name of the generic type
  /// of [Scanner], or `null` if the type argument was omitted.
  /// [libraryPrefixes] contains the result of [resolvePrefixes].
  String generateScanner(List<PatternWithInitializer> patterns,
      {@required String scannerName,
      @required String patternTypeName,
      @required Map<String, String> libraryPrefixes});
}

/// Ensures that the element annotated with [InjectScanner] is a valid target
/// for the annotation.
///
/// Throws an [InvalidGenerationSourceError] if
///   * the annotated element is not a top level variable,
///   * the annotated variable is not declared `const`,
///   * or the annotated variable is not initialized with a variable named
///     `'_$' + variableName`.
void validateAnnotatedElement(Element element) {
  if (element is! TopLevelVariableElement) {
    throw new InvalidGenerationSourceError(
        '@InjectScanner must annotate a top level variable',
        element: element);
  }
  final TopLevelVariableElement variable = element;
  if (!variable.isConst) {
    throw new InvalidGenerationSourceError(
        '@InjectScanner must annotate a `const` variable',
        element: variable);
  }
  final expectedName = generatedNamesPrefix + variable.name;
  final initializer = variable.computeNode().initializer;
  if (!(initializer is Identifier && initializer.name == expectedName)) {
    throw new InvalidGenerationSourceError(
        'The injection point must be initialized to `$expectedName`, '
        ' the generated variable that holds the scanner',
        element: variable);
  }
}

/// Returns the name of the generic type argument of the generated [Scanner], or
/// `null` if the analyzed code doesn't specify a type.
String resolvePatternTypeName(TopLevelVariableElement variable) {
  final type = variable.type;
  if (type == null) {
    return null;
  }
  if (!const TypeChecker.fromRuntime(Scanner).isAssignableFromType(type)) {
    throw new InvalidGenerationSourceError(
        'The annotated variable must be of type Scanner',
        element: variable);
  }
  return (type as ParameterizedType).typeArguments.single.name;
}

/// If [regularScannerLibraryUri] was imported with a library prefix, returns the prefix
/// String that has to be prepended in generated code to access names from this
/// package.
///
/// For example, if a library contains the import statement
/// ```dart
/// import 'package:regular_scanner/regular_scanner.dart' as rs show Scanner;
/// ```
/// then this function will map [Scanner] to the string `'rs.'`, because the
/// [Scanner] constructor must be invoked with `const rs.Scanner()`.
///
/// The result contains keys `'Scanner'`, `'State'` and `'Transition'`.
Map<String, String> resolvePrefixes(LibraryElement library) {
  library.prefixes.first.id;
  final relevantClasses = ['Scanner', 'State', 'Transition'];
  final result = <String, String>{};
  for (final import in library.imports) {
    if (import.uri != regularScannerLibraryUri) {
      continue;
    }
    final prefix = import.prefix != null ? '${import.prefix.name}.' : '';
    for (final cls in relevantClasses) {
      if (import.namespace.getPrefixed(import.prefix.name, cls) != null) {
        result[cls] = prefix;
      }
    }
  }
  if (result.length != relevantClasses.length) {
    throw new InvalidGenerationSourceError(
        'The classes `Scanner`, `State` and `Transition` must be visible '
        'in the library containing the scanner',
        element: library);
  }
  return result;
}

/// An instance of this class represents a pattern from an [InjectScanner]
/// annotation. It contains the [regularExpression] and [precedence] that are
/// needed for the scanner construction algorithm, and the information how to
/// reconstruct the initial annotation argument. Because
class PatternWithInitializer extends Pattern {
  PatternWithInitializer(
      String regularExpression, int precedence, this.initializerExpression)
      : super(regularExpression, precedence: precedence);

  factory PatternWithInitializer.fromAnnotation(ConstantReader pattern) {
    assert(pattern.instanceOf(isInjectScanner));

    final regexpString = pattern.read('regularExpression').stringValue;
    final precedence = pattern.read('precedence').intValue;
    // TODO: Resolve `initializer` from AST
    final initializer = null;
    return new PatternWithInitializer(regexpString, precedence, initializer);
  }

  final String initializerExpression;
}

/// Encodes the built scanner as a `const` [TableDrivenScanner].
class TableDrivenScannerGenerator extends ScannerGenerator {
  @override
  String generateScanner(List<PatternWithInitializer> patterns,
      {@required String scannerName,
      @required String patternTypeName,
      @required Map<String, String> libraryPrefixes}) {
    final scanner = new Scanner<PatternWithInitializer>(patterns)
        as TableDrivenScanner<PatternWithInitializer>;

    final result = new StringBuffer()
      ..write(r'const _$')
      ..write(scannerName)
      ..write(' = ')
      ..write('const ')
      ..write(libraryPrefixes['Scanner'])
      ..write('Scanner');
    if (patternTypeName != null) {
      result..write('<')..write(patternTypeName)..write('>');
    }
    result.write('.withParseTable(const [');
    for (final state in scanner.states) {
      result.write('const ${libraryPrefixes["State"]}State(const [');
      for (final transition in state.transitions) {
        result
          ..write('const ${libraryPrefixes["Transition"]}Transition(')
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
