import 'package:dartshell/declaration_processors/return_type.dart';

import 'external_declaration_processor.dart';

class RunSilentExternalDeclarationProcessor
    extends ExternalDeclarationProcessor {
  static final _signatures = [
    Signature.withPositional(
      ReturnType.stdout.signature,
      'runSilent',
      ['String cmd'],
      ['List<String> args', 'String stdin'],
    ),
    Signature.withNamed(
      ReturnType.stdout.signature,
      'runSilent',
      ['String cmd'],
      ['List<String> args', 'String stdin'],
    ),
    Signature.withPositional(
      ReturnType.stdoutStderr.signature,
      'runSilent',
      ['String cmd'],
      ['List<String> args', 'String stdin'],
    ),
    Signature.withNamed(
      ReturnType.stdoutStderr.signature,
      'runSilent',
      ['String cmd'],
      ['List<String> args', 'String stdin'],
    ),
  ];

  const RunSilentExternalDeclarationProcessor() : super(true);

  @override
  String get description =>
      "Run the specified command. The command's stderr is echoed. The return value contains stdout (and stderr, for the record version).";

  @override
  List<Signature> signatures() => _signatures;

  @override
  String implementationForSignature(Signature signature) {
    final returnType = ReturnType.of(signature.returnType);
    final returnStatement = returnType == ReturnType.stdout
        ? 'systemEncoding.decode(stdoutBytes)'
        : '(systemEncoding.decode(stdoutBytes), systemEncoding.decode(stderrBytes))';
    final optionalParams = signature.optionalParameterList(withDefaults: true)!;

    return '''${returnType.signature} ${signature.name}(String cmd, $optionalParams) async {
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
