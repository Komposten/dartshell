import 'dart:io';

import 'package:dartshell/dartshell_core.dart' as core;

class Arguments {
  final String? script;
  final List<String> scriptArgs;
  final bool verbose;
  final bool showHelp;
  final bool showSignatures;
  final bool createScript;

  Arguments({
    required this.script,
    required this.scriptArgs,
    required this.verbose,
    required this.showHelp,
    required this.showSignatures,
    required this.createScript,
  });

  factory Arguments.from(List<String> args) {
    // TODO Update to only accept --verbose is specified _before_ the dart file path
    final verbose = args.contains('--verbose');
    final showHelp = args.contains('--help');
    final showSignatures = args.contains('--signatures');
    final createScript = args.contains('--new');
    final scriptAndArgs = args
        .where(
          (argument) => ![
            '--verbose',
            '--help',
            '--signatures',
            '--new',
          ].contains(argument),
        )
        .toList();

    if (showHelp) {
      return Arguments(
        script: null,
        scriptArgs: const [],
        verbose: verbose,
        showHelp: true,
        showSignatures: false,
        createScript: false,
      );
    }

    if (showSignatures) {
      if (createScript || scriptAndArgs.isNotEmpty) {
        throw '--signatures cannot be used with --new or a dart file';
      }
      return Arguments(
        script: null,
        scriptArgs: const [],
        verbose: verbose,
        showHelp: false,
        showSignatures: true,
        createScript: false,
      );
    }

    if (createScript) {
      if (scriptAndArgs.length != 1) {
        throw '--new requires exactly one dart file path';
      }
      return Arguments(
        script: scriptAndArgs.single,
        scriptArgs: const [],
        verbose: verbose,
        showHelp: false,
        showSignatures: false,
        createScript: true,
      );
    }

    try {
      return Arguments(
        script: scriptAndArgs.first,
        scriptArgs: scriptAndArgs.skip(1).toList(),
        verbose: verbose,
        showHelp: false,
        showSignatures: false,
        createScript: false,
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
    stderr.writeln('Error: $e');
    _printUsage();
    exit(127);
  }

  if (parsed.showHelp) {
    _printUsage();
    return;
  }

  if (parsed.showSignatures) {
    _printAvailableSignatures();
    return;
  }

  if (parsed.createScript) {
    try {
      await _createScript(parsed.script!);
    } catch (e) {
      stderr.writeln('Error: $e');
      exit(1);
    }
    return;
  }

  final exitCode = await core.run(
    parsed.script!,
    parsed.scriptArgs,
    verbose: parsed.verbose,
  );
  if (exitCode != 0) {
    exit(exitCode);
  }
}

void _printUsage() {
  print('Usage: dartshell [options] <dart-file> [args...]');
  print('       dartshell [options] --signatures');
  print('       dartshell [options] --new <dart-file>');
  print('');
  print('Options:');
  print('  --help        Show this usage information.');
  print('  --verbose     Print additional execution details.');
  print(
    '  --signatures  List the external function signatures available to scripts.',
  );
  print('  --new         Create a new script from a template at <dart-file>.');
  print('');
  print('Arguments:');
  print('  <dart-file>   Path to the Dart script to run or create with --new.');
  print('  [args...]     Arguments passed to the Dart script.');
}

Future<void> _createScript(String scriptPath) async {
  final existingType = await FileSystemEntity.type(scriptPath);
  if (existingType == FileSystemEntityType.directory) {
    throw '$scriptPath is a directory';
  }
  if (existingType != FileSystemEntityType.notFound) {
    throw '$scriptPath already exists';
  }

  final scriptFile = File(scriptPath);
  await scriptFile.create(recursive: true, exclusive: true);
  await scriptFile.writeAsString(_newScriptTemplate());
  print('Created $scriptPath');
}

String _newScriptTemplate() {
  final template = StringBuffer('''#!/usr/bin/env dartshell

void main() {
  // Script code here.
  // You may use all available Dart features.
}

// Dartshell function declarations; uncomment the ones you need
''');

  for (final line in _availableSignatureLines()) {
    template.writeln('// $line');
  }

  return template.toString();
}

void _printAvailableSignatures() {
  print(
    'Note: optional positional or named parameters may be omitted from the signature.',
  );

  for (final line in _availableSignatureLines()) {
    print(line.startsWith('external ') ? '  $line' : line);
  }
}

List<String> _availableSignatureLines() => [
  for (final entry in core.availableExternalSignatures()) ...[
    '',
    '${entry.name}: ${entry.description}',
    for (final signature in entry.signatures) 'external $signature;',
  ],
];
