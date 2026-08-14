import 'package:analyzer/dart/ast/ast.dart';
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
      expect(
        output,
        contains(
          'Future<String> run(String cmd, [List<String> args = const []]) async',
        ),
      );
      expect(output, contains('final result = await Process.run(cmd, args);'));
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

    test('accepts additional declaration processors', () {
      const source = 'external int answer();\n';
      final preprocessor = ScriptPreprocessor(
        processors: const [_AnswerProcessor()],
      );

      expect(preprocessor.preprocess(source), 'int answer() => 42;\n');
    });
  });
}

class _AnswerProcessor implements ExternalDeclarationProcessor {
  const _AnswerProcessor();

  @override
  bool get requiresDartIo => false;

  @override
  String implementationFor(FunctionDeclaration declaration) =>
      'int answer() => 42;';

  @override
  bool supports(FunctionDeclaration declaration) =>
      declaration.name.lexeme == 'answer';
}
