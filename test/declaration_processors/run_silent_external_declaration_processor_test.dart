import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

import 'package:dartshell/declaration_processors/run_silent_external_declaration_processor.dart';
import 'package:test/test.dart';

void main() {
  group('RunSilentExternalDeclarationProcessor', () {
    const processor = RunSilentExternalDeclarationProcessor();

    test('generates stdin forwarding', () {
      final declaration = _externalFunctionDeclaration(
        'external Future<String> runSilent('
        'String cmd, [List<String> args, String stdin]);',
      );

      expect(
        processor.implementationFor(declaration),
        allOf(
          contains('process.stdin.write(stdin);'),
          contains('await process.stdin.close();'),
        ),
      );
    });
  });
}

FunctionDeclaration _externalFunctionDeclaration(String source) =>
    parseString(content: source).unit.declarations.single
        as FunctionDeclaration;
