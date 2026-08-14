import 'dart:io';

import 'package:dartshell/dartshell_core.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
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
          contains('Process.run(cmd, args)'),
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

const _scriptThatExitsWithArgumentCount = '''
import 'dart:io';

void main(List<String> args) {
  exit(args.length);
}

external Future<String> run(String cmd, [List<String> args]);
''';

const _scriptThatAlwaysExitsWithThree = '''
import 'dart:io';

void main(List<String> args) {
  exit(3);
}

external Future<String> run(String cmd, [List<String> args]);
''';
