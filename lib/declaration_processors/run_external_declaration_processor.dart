import 'package:dartshell/declaration_processors/resolved_parameters.dart';
import 'package:dartshell/declaration_processors/return_type.dart';
import 'package:dartshell/declaration_processors/signature.dart';

import 'external_declaration_processor.dart';

/// Implements the shell command declaration:
///
/// ```dart
/// external Future<String> run(String cmd, [List<String> args, String stdin, bool silent]);
/// ```
class RunExternalDeclarationProcessor extends ExternalDeclarationProcessor {
  static final _signatures = [
    Signature(
      ReturnType.stdout.signature,
      'run',
      ['String cmd'],
      ['List<String> args', 'String stdin', 'bool silent'],
    ),
    Signature(
      ReturnType.stdoutStderr.signature,
      'run',
      ['String cmd'],
      ['List<String> args', 'String stdin', 'bool silent'],
    ),
  ];

  const RunExternalDeclarationProcessor() : super(true);

  @override
  String get description => '''
Runs a command with the supplied arguments.
By default, its output is forwarded to this process's stdout and stderr. Set `silent` to suppress stdout; stderr is still forwarded.
Pass `stdin` to provide input to the command.
The returned future completes with stdout, or with a record containing both stdout and stderr.
''';

  @override
  List<Signature> signatures() => _signatures;

  @override
  String implementationForSignature(
    Signature signature,
    ResolvedParameters parameters,
  ) {
    final returnType = ReturnType.of(signature.returnType);
    final returnStatement = returnType == ReturnType.stdout
        ? 'systemEncoding.decode(stdoutBytes)'
        : '(systemEncoding.decode(stdoutBytes), systemEncoding.decode(stderrBytes))';

    return '''${returnType.signature} ${signature.name}(${signature.parameterStringFor(parameters)}) async {
  final process = await Process.start(cmd, args);
  final stdoutBytes = <int>[];
  final stderrBytes = <int>[];

  final stdoutDone = process.stdout.listen((output) {
    if (!silent) {
      stdout.add(output);
    }
    stdoutBytes.addAll(output);
  }).asFuture<void>();
  final stderrDone = process.stderr.listen((output) {
    stderr.add(output);
    stderrBytes.addAll(output);
  }).asFuture<void>();

  process.stdin.write(stdin);
  await process.stdin.close();

  final results = await Future.wait([process.exitCode, stdoutDone, stderrDone]);
  final exitCode = results.first as int;

  if (exitCode != 0) {
    throw ProcessException(cmd, args, systemEncoding.decode(stderrBytes), exitCode);
  }

  return $returnStatement;
}''';
  }
}
