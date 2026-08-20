import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

import 'package:dartshell/declaration_processors/run_external_declaration_processor.dart';
import 'package:test/test.dart';

void main() {
  group('ExternalDeclarationProcessor', () {
    const processor = RunExternalDeclarationProcessor();

    test('uses the matched signature to generate an implementation', () {
      final declaration = _externalFunctionDeclaration(
        'external Future<(String, String)> run('
        'String cmd, [List<String> args]);',
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
            'String cmd, [List<String> args = const []]) async',
          ),
          contains(
            'return (systemEncoding.decode(stdoutBytes), '
            'systemEncoding.decode(stderrBytes));',
          ),
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
