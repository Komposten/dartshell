import 'package:dartshell/script_preprocessor.dart';
import 'package:test/test.dart';

void main() {
  group('ScriptPreprocessor', () {
    test('implements the supported asynchronous run declaration', () {
      const source = '''void main() async {
  final output = await run('git', ['status', '--porcelain']);
  print(output);
}

external Future<String> run(String cmd, [List<String> args]);
''';

      final output = ScriptPreprocessor().preprocess(source);

      expect(output, contains("import 'dart:io';"));
      expect(output, contains('Future<String> run(String cmd, [List<String> args = const []]) async'));
      expect(output, contains('final process = await Process.start(cmd, args);'));
      expect(output, contains('stdout.add(output);'));
      expect(output, contains('stderr.add(output);'));
      expect(output, isNot(contains('external Future<String> run')));
    });

    test('does not add dart:io when it is already imported', () {
      const source = '''import 'dart:io';

external Future<String> run(String cmd, List<String> args);
''';

      final output = ScriptPreprocessor().preprocess(source);

      expect(RegExp("import 'dart:io';").allMatches(output), hasLength(1));
    });

    test('leaves unsupported external declarations unchanged', () {
      const source = 'external Future<int> runCode(String cmd);\n';

      expect(ScriptPreprocessor().preprocess(source), source);
    });
  });
}
