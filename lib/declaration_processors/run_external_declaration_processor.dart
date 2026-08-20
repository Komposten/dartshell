import 'package:dartshell/declaration_processors/return_type.dart';

import 'external_declaration_processor.dart';

/// Implements the shell command declaration:
///
/// ```dart
/// external Future<String> run(String cmd, [List<String> args]);
/// ```
class RunExternalDeclarationProcessor extends ExternalDeclarationProcessor {
  static final _signatures = {
    ReturnType.stdout: [
      Signature.withPositional(
        ReturnType.stdout.signature,
        'run',
        'String cmd',
        'List<String> args',
      ),
    ],
    ReturnType.stdoutStderr: [
      Signature.withPositional(
        ReturnType.stdoutStderr.signature,
        'run',
        'String cmd',
        'List<String> args',
      ),
    ],
  };

  const RunExternalDeclarationProcessor() : super(true);

  @override
  String get description =>
      "Run the specified command. The command's stdout and stderr are echoed. The return value contains stdout (and stderr, for the record version).";

  @override
  List<Signature> signatures() => _signatures.values.expand((e) => e).toList();

  @override
  String implementationForSignature(Signature signature) {
    final returnType = ReturnType.of(signature.returnType);
    final returnStatement = returnType == ReturnType.stdout
        ? 'systemEncoding.decode(stdoutBytes)'
        : '(systemEncoding.decode(stdoutBytes), systemEncoding.decode(stderrBytes))';

    return '''${returnType.signature} ${signature.name}(String cmd, [List<String> args = const []]) async {
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

  return $returnStatement;
}''';
  }
}
