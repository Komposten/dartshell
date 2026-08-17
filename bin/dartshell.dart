import 'dart:io';

import 'package:dartshell/dartshell_core.dart' as core;

class Arguments {
  final String? script;
  final List<String> scriptArgs;
  final bool verbose;
  final bool showSignatures;

  Arguments({required this.script, required this.scriptArgs, required this.verbose, required this.showSignatures});

  factory Arguments.from(List<String> args) {
    final verbose = args.contains('--verbose');
    final showSignatures = args.contains('--signatures');
    final scriptAndArgs = args.where((argument) => !['--verbose', '--signatures'].contains(argument));

    if (showSignatures) {
      if (scriptAndArgs.isNotEmpty) {
        throw '--signatures cannot be used with a dart file';
      }
      return Arguments(script: null, scriptArgs: const [], verbose: verbose, showSignatures: true);
    }

    try {
      return Arguments(
        script: scriptAndArgs.first,
        scriptArgs: scriptAndArgs.skip(1).toList(),
        verbose: verbose,
        showSignatures: false,
      );
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
    print('       dartshell [--verbose] --signatures');
    exit(127);
  }

  if (parsed.showSignatures) {
    _printAvailableSignatures();
    return;
  }

  final exitCode = await core.run(parsed.script!, parsed.scriptArgs, verbose: parsed.verbose);
  if (exitCode != 0) {
    exit(exitCode);
  }
}

void _printAvailableSignatures() {
  print('Note: optional positional or named parameters may be omitted from the signature.');

  for (final entry in core.availableExternalSignatures()) {
    print('');
    print('${entry.name}: ${entry.description}');
    for (final signature in entry.signatures) {
      print('  external $signature;');
    }
  }
}
