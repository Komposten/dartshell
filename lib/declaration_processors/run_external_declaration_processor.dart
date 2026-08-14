import 'package:analyzer/dart/ast/ast.dart';

import 'external_declaration_processor.dart';

/// Implements the shell command declaration:
///
/// ```dart
/// external Future<String> run(String cmd, [List<String> args]);
/// ```
class RunExternalDeclarationProcessor implements ExternalDeclarationProcessor {
  const RunExternalDeclarationProcessor();

  @override
  bool get requiresDartIo => true;

  @override
  bool supports(FunctionDeclaration declaration) {
    return declaration.name.lexeme == 'run' &&
        declaration.returnType?.toSource() == 'Future<String>' &&
        _matchesParameterList(
          declaration.functionExpression.parameters?.toSource() ?? '',
        );
  }

  static bool _matchesParameterList(String parameters) {
    final compact = parameters.replaceAll(RegExp(r'\s+'), '');
    return compact == '(Stringcmd,List<String>args)' ||
        compact == '(Stringcmd,[List<String>args])';
  }

  @override
  String implementationFor(FunctionDeclaration declaration) {
    return '''Future<String> run(String cmd, [List<String> args = const []]) async {
  final process = await Process.start(cmd, args);
  final stdoutBytes = <int>[];
  final stderrBytes = <int>[];

  final stdoutDone = process.stdout.listen((output) {
    stdout.add(output);
    stdoutBytes.addAll(output);
  }).asFuture<void>();
  final stderrDone = process.stderr.listen((output) {
    stderr.add(output);
    stderrBytes.addAll(output);
  }).asFuture<void>();

  final results = await Future.wait([process.exitCode, stdoutDone, stderrDone]);
  final exitCode = results.first as int;

  if (exitCode != 0) {
    throw ProcessException(cmd, args, systemEncoding.decode(stderrBytes), exitCode);
  }

  return systemEncoding.decode(stdoutBytes);
}''';
  }
}
