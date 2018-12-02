import 'dart:io';
import 'dart:isolate';

import 'package:front_end/src/fasta/scanner.dart' as fasta;
import 'package:glob/glob.dart';
import 'package:package_config/packages_file.dart';

void main(List<String> args) async {
  final files = await loadBenchmarkFiles();
  final result = fasta.scanString(files.first);
  var token = result.tokens;
  while (token != null) {
    print('${token.type}: ${token.lexeme}');
    token = token.next;
  }
}

Future<List<String>> loadBenchmarkFiles(
    [String fromPackage = 'regular_scanner']) async {
  final packageConfigUri = await Isolate.packageConfig;
  final packageUris =
      parse(File.fromUri(packageConfigUri).readAsBytesSync(), packageConfigUri);

  return Glob('**.dart')
      .listSync(root: packageUris[fromPackage].toFilePath())
      .map((file) => (file as File).readAsStringSync())
      .toList();
}
