import 'package:analyzer/dart/ast/ast.dart';
import 'package:dartshell/declaration_processors/return_type.dart';

import 'external_declaration_processor.dart';

class RunSilentExternalDeclarationProcessor
    extends ExternalDeclarationProcessor {
  static final _signatures = {
    ReturnType.stdout: [
      Signature.withPositional(
        'Future<String>',
        'runSilent',
        'String cmd',
        'List<String> args',
      ),
    ],
    ReturnType.stdoutStderr: [
      Signature.withPositional(
        'Future<(String, String)>',
        'runSilent',
        'String cmd',
        'List<String> args',
      ),
    ],
  };

  const RunSilentExternalDeclarationProcessor() : super(true);

  @override
  String get description =>
      "Run the specified command. The command's stderr is echoed. The return value contains stdout (and stderr, for the record version).";

  @override
  List<Signature> signatures() => _signatures.values.expand((e) => e).toList();

  @override
  String implementationFor(FunctionDeclaration declaration) {
    final entry = _signatures.entries
        .where(
          (entry) =>
              entry.value.any((signature) => signature.matches(declaration)),
        )
        .first;
    final returnType = entry.key == ReturnType.stdout
        ? 'systemEncoding.decode(stdoutBytes)'
        : '(systemEncoding.decode(stdoutBytes), systemEncoding.decode(stderrBytes))';

    return '''Future<String> run(String cmd, [List<String> args = const []]) async {
  final process = await Process.start(cmd, args);
  final stdoutBytes = <int>[];
  final stderrBytes = <int>[];

  final stdoutDone = process.stdout.listen((output) {
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

  return $returnType;
}''';
  }
}
