import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

import 'package:dartshell/declaration_processors/run_external_declaration_processor.dart';
import 'package:test/test.dart';

void main() {
  group('RunExternalDeclarationProcessor', () {
    const processor = RunExternalDeclarationProcessor();

    test('uses the matched signature to generate an implementation', () {
      final declaration = _externalFunctionDeclaration(
        'external Future<(String, String)> run('
        'String cmd, [List<String> args, String stdin, bool silent]);',
      );

      final signature = processor.signature(declaration);

      expect(signature, isNotNull);
      expect(signature!.returnType, 'Future<(String, String)>');
      expect(processor.supports(declaration), isTrue);
      expect(
        processor.implementationFor(declaration),
        allOf(
          startsWith(
            'Future<(String, String)> run('
            "String cmd, [List<String> args = const [], String stdin = '', bool silent = false]) async",
          ),
          contains('process.stdin.write(stdin);'),
          contains('await process.stdin.close();'),
          contains(
            'return (systemEncoding.decode(stdoutBytes), '
            'systemEncoding.decode(stderrBytes));',
          ),
        ),
      );
    });

    test('supplies defaults for omitted parameters', () {
      final declaration = _externalFunctionDeclaration(
        'external Future<String> run(String cmd, {required String stdin});',
      );

      expect(
        processor.implementationFor(declaration),
        startsWith(
          'Future<String> run('
          'String cmd, {required String stdin, List<String> args = const [], bool silent = false}) async',
        ),
      );
    });

    test('preserves reordered parameters in the generated implementation', () {
      final declaration = _externalFunctionDeclaration(
        'external Future<String> run('
        'List<String> args, String stdin, String cmd, bool silent);',
      );

      expect(
        processor.implementationFor(declaration),
        allOf(
          startsWith(
            'Future<String> run('
            'List<String> args, String stdin, String cmd, bool silent) async',
          ),
          contains('Process.start(cmd, args);'),
          contains('process.stdin.write(stdin);'),
        ),
      );
    });

    test('rejects implementation requests for unsupported declarations', () {
      final declaration = _externalFunctionDeclaration(
        'external Future<int> run(String cmd);',
      );

      expect(processor.signature(declaration), isNull);
      expect(processor.supports(declaration), isFalse);
      expect(
        () => processor.implementationFor(declaration),
        throwsArgumentError,
      );
    });
  });
}

FunctionDeclaration _externalFunctionDeclaration(String source) =>
    parseString(content: source).unit.declarations.single
        as FunctionDeclaration;
