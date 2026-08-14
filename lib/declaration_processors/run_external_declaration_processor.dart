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
  final result = await Process.run(cmd, args);
  stdout.write(result.stdout);
  stderr.write(result.stderr);

  if (result.exitCode != 0) {
    throw ProcessException(cmd, args, result.stderr.toString(), result.exitCode);
  }

  return result.stdout as String;
}''';
  }
}
