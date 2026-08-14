import 'dart:io';

import 'package:dartshell/dartshell_core.dart' as core;

class Arguments {
  final String script;
  final List<String> scriptArgs;
  final bool verbose;

  Arguments({required this.script, required this.scriptArgs, required this.verbose});

  factory Arguments.from(List<String> args) {
    bool verbose = args.contains('--verbose');
    try {
      final scriptAndArgs = args.where((a) => !['--verbose'].contains(a));
      return Arguments(script: scriptAndArgs.first, scriptArgs: scriptAndArgs.skip(1).toList(), verbose: verbose);
    } catch (e) {
      throw 'dart-file must be provided';
    }
  }
}

void main(List<String> args) async {
  Arguments parsed;
  try {
    parsed = Arguments.from(args);
  } catch (e) {
    print('Usage: dartshell [--verbose] <dart-file> <args>');
    exit(127);
  }

  final exitCode = await core.run(parsed.script, parsed.scriptArgs, verbose: parsed.verbose);
  if (exitCode != 0) {
    exit(exitCode);
  }
}
