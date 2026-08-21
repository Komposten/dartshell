import 'dart:io';

import 'package:dartshell/dartshell_core.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('availableExternalSignatures', () {
    test('groups every built-in signature by function name', () {
      final signaturesByName = availableExternalSignatures();

      expect(signaturesByName.map((s) => s.name), ['run']);
      expect(
        signaturesByName
            .where((s) => s.name == 'run')
            .expand((e) => e.signatures)
            .map((signature) => signature.toString()),
        [
          'Future<String> run(String cmd, [List<String> args, String stdin, bool silent])',
          'Future<(String, String)> run(String cmd, [List<String> args, String stdin, bool silent])',
        ],
      );
    });
  });

  group('dartshell --new', () {
    late Directory scriptDirectory;

    setUp(() async {
      scriptDirectory = await Directory.systemTemp.createTemp(
        'dartshell_new_test_',
      );
    });

    tearDown(() async {
      await scriptDirectory.delete(recursive: true);
    });

    test(
      'creates a template with every available external declaration',
      () async {
        final scriptPath = path.join(scriptDirectory.path, 'script.dart');

        final result = await _runDartshell(['--new', scriptPath]);

        expect(result.exitCode, 0, reason: result.stderr);
        final script = await File(scriptPath).readAsString();
        expect(
          script,
          startsWith('''#!/usr/bin/env dartshell

void main(List<String> args) async {
  // Script code here.
  // You may use all available Dart features.
}

// Dartshell function declarations; uncomment the ones you need
'''),
        );
        for (final entry in availableExternalSignatures()) {
          expect(script, contains('// ${entry.name}: ${entry.description}'));
          for (final signature in entry.signatures) {
            expect(script, contains('// external $signature;'));
          }
        }
      },
    );

    test('rejects a directory path', () async {
      final result = await _runDartshell(['--new', scriptDirectory.path]);

      expect(result.exitCode, 1);
      expect(result.stderr, contains('${scriptDirectory.path} is a directory'));
    });
  });

  group('run', () {
    late Directory scriptDirectory;
    late File scriptFile;
    late File buildFile;
    late File executableFile;

    setUp(() async {
      scriptDirectory = await Directory.systemTemp.createTemp(
        'dartshell_core_test_',
      );
      scriptFile = File(path.join(scriptDirectory.path, 'script.dart'));

      final buildName =
          '${path.basename(scriptFile.path)}-${scriptFile.absolute.path.hashCode}';
      buildFile = File(
        path.join(Directory.systemTemp.path, 'dartshell', 'build', buildName),
      );
      executableFile = File(
        path.join(Directory.systemTemp.path, 'dartshell', 'bin', buildName),
      );
    });

    tearDown(() async {
      await scriptDirectory.delete(recursive: true);
      if (await buildFile.exists()) {
        await buildFile.delete();
      }
      if (await executableFile.exists()) {
        await executableFile.delete();
      }
    });

    test('rejects a path that does not name a file', () async {
      final missingPath = path.join(scriptDirectory.path, 'missing.dart');

      await expectLater(
        () => run(missingPath, const []),
        throwsA('$missingPath does not exist or is not a file'),
      );
    });

    test(
      'preprocesses, compiles, executes, and recompiles changed scripts',
      () async {
        await scriptFile.writeAsString(_scriptThatExitsWithArgumentCount);

        expect(await run(scriptFile.path, const ['first', 'second']), 2);
        expect(
          await buildFile.readAsString(),
          contains('Process.start(cmd, args)'),
        );

        final initialBuildModified = await buildFile.lastModified();
        expect(await run(scriptFile.path, const ['again']), 1);
        expect(await buildFile.lastModified(), initialBuildModified);

        await Future<void>.delayed(const Duration(seconds: 1));
        await scriptFile.writeAsString(_scriptThatAlwaysExitsWithThree);

        expect(await run(scriptFile.path, const []), 3);
        expect(await buildFile.readAsString(), contains('exit(3);'));
      },
    );
  });
}

Future<ProcessResult> _runDartshell(List<String> args) => Process.run(
  Platform.resolvedExecutable,
  ['run', 'bin/dartshell.dart', ...args],
  workingDirectory: Directory.current.path,
);

const _scriptThatExitsWithArgumentCount = '''
import 'dart:io';

void main(List<String> args) async {
  exit(args.length);
}

external Future<String> run(String cmd, [List<String> args, String stdin]);
''';

const _scriptThatAlwaysExitsWithThree = '''
import 'dart:io';

void main(List<String> args) async {
  exit(3);
}

external Future<String> run(String cmd, [List<String> args, String stdin]);
''';
