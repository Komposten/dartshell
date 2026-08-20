import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

import 'package:dartshell/declaration_processors/external_declaration_processor.dart';
import 'package:test/test.dart';

void main() {
  group('Signature', () {
    test('formats a required-only signature', () {
      final signature = Signature('Future<String>', 'run', ['String cmd']);

      expect(signature.requiredParameterList, 'String cmd');
      expect(signature.optionalParameterList(), isNull);
      expect(signature.toString(), 'Future<String> run(String cmd)');
    });

    test('matches a required-only function declaration', () {
      final signature = Signature('Future<String>', 'run', ['String cmd']);

      expect(
        signature.matches(
          _externalFunctionDeclaration(
            'external Future<String> run(String cmd);',
          ),
        ),
        isTrue,
      );
    });

    test(
      'matches positional functions with and without optional arguments',
      () {
        final signature = Signature.withPositional(
          'Future<String>',
          'run',
          ['String cmd'],
          ['List<String> args', 'String stdin'],
        );

        expect(
          signature.matches(
            _externalFunctionDeclaration(
              'external Future<String> run(String cmd);',
            ),
          ),
          isTrue,
        );
        expect(
          signature.matches(
            _externalFunctionDeclaration(
              'external Future<String> run('
              'String cmd, [List<String> args, String stdin]);',
            ),
          ),
          isTrue,
        );
      },
    );

    test('matches named functions with and without optional arguments', () {
      final signature = Signature.withNamed(
        'Future<String>',
        'run',
        ['String cmd'],
        ['List<String> args', 'String stdin'],
      );

      expect(
        signature.matches(
          _externalFunctionDeclaration(
            'external Future<String> run(String cmd);',
          ),
        ),
        isTrue,
      );
      expect(
        signature.matches(
          _externalFunctionDeclaration(
            'external Future<String> run('
            'String cmd, {List<String> args, String stdin});',
          ),
        ),
        isTrue,
      );
    });

    test(
      'does not match declarations with a different return type, name, or parameters',
      () {
        final signature = Signature('Future<String>', 'run', ['String cmd']);

        expect(
          signature.matches(
            _externalFunctionDeclaration(
              'external Future<int> run(String cmd);',
            ),
          ),
          isFalse,
        );
        expect(
          signature.matches(
            _externalFunctionDeclaration(
              'external Future<String> runSilent(String cmd);',
            ),
          ),
          isFalse,
        );
        expect(
          signature.matches(
            _externalFunctionDeclaration(
              'external Future<String> run(List<String> args);',
            ),
          ),
          isFalse,
        );
      },
    );
  });
}

FunctionDeclaration _externalFunctionDeclaration(String source) =>
    parseString(content: source).unit.declarations.single
        as FunctionDeclaration;
