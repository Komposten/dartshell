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
        'String cmd, [List<String> args, String stdin]);',
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
            "String cmd, [List<String> args = const [], String stdin = '']) async",
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

    test('supplies a default when stdin is omitted', () {
      final declaration = _externalFunctionDeclaration(
        'external Future<String> run(String cmd, [List<String> args]);',
      );

      expect(
        processor.implementationFor(declaration),
        startsWith(
          'Future<String> run(String cmd, '
          "[List<String> args = const [], String stdin = '']) async",
        ),
      );
    });

    test('supplies a default when args is omitted', () {
      final declaration = _externalFunctionDeclaration(
        'external Future<String> run(String cmd, {required String stdin});',
      );

      expect(
        processor.implementationFor(declaration),
        startsWith(
          'Future<String> run('
          'String cmd, {required String stdin, List<String> args = const []}) async',
        ),
      );
    });

    test('supplies defaults when args and stdin are omitted', () {
      final declaration = _externalFunctionDeclaration(
        'external Future<String> run(String cmd);',
      );

      expect(
        processor.implementationFor(declaration),
        startsWith(
          'Future<String> run(String cmd, '
          "[List<String> args = const [], String stdin = '']) async",
        ),
      );
    });

    test('preserves reordered parameters in the generated implementation', () {
      final declaration = _externalFunctionDeclaration(
        'external Future<String> run('
        'List<String> args, String stdin, String cmd);',
      );

      expect(
        processor.implementationFor(declaration),
        allOf(
          startsWith(
            'Future<String> run('
            'List<String> args, String stdin, String cmd) async',
          ),
          contains('Process.start(cmd, args);'),
          contains('process.stdin.write(stdin);'),
        ),
      );
    });

    test('supports named optional parameters', () {
      final declaration = _externalFunctionDeclaration(
        'external Future<String> run('
        '{required String cmd, List<String> args, String stdin});',
      );

      expect(
        processor.implementationFor(declaration),
        allOf(
          startsWith(
            'Future<String> run('
            "{required String cmd, List<String> args = const [], String stdin = ''}) async",
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
