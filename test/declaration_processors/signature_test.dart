import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dartshell/declaration_processors/resolved_parameters.dart';

import 'package:dartshell/declaration_processors/signature.dart';
import 'package:test/test.dart';

void main() {
  group('Signature', () {
    test('formats a signature', () {
      final signature = Signature(
        'Future<String>',
        'run',
        ['String cmd'],
        ['List<String> args'],
      );

      expect(
        signature.toString(),
        'Future<String> run(String cmd, [List<String> args])',
      );
    });

    test('formats a signature with ANSI syntax highlighting', () {
      final signature = Signature(
        'Future<String>',
        'run',
        ['String cmd'],
        ['List<String> args'],
      );

      expect(
        signature.toString(highlighted: true),
        '\x1B[36mFuture<String>\x1B[0m \x1B[32mrun\x1B[0m'
        '\x1B[2m(\x1B[0m\x1B[33mString cmd\x1B[0m'
        '\x1B[2m, [\x1B[0m\x1B[33mList<String> args\x1B[0m'
        '\x1B[2m]\x1B[0m\x1B[2m)\x1B[0m',
      );
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

    test('matches functions with optional positional arguments', () {
      final signature = Signature(
        'Future<String>',
        'run',
        ['String cmd'],
        ['List<String> args', 'String stdin'],
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
    });

    test('matches functions with named arguments', () {
      final signature = Signature(
        'Future<String>',
        'run',
        ['String cmd'],
        ['List<String> args', 'String stdin'],
      );

      expect(
        signature.matches(
          _externalFunctionDeclaration(
            'external Future<String> run('
            'String cmd, {required List<String> args, String stdin});',
          ),
        ),
        isTrue,
      );
    });

    test('matches functions with optional arguments omitted', () {
      final signature = Signature(
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
    });

    test('matches functions with rearranged arguments', () {
      final signature = Signature(
        'Future<String>',
        'run',
        ['String cmd', 'List<String> args'],
        ['String stdin'],
      );

      expect(
        signature.matches(
          _externalFunctionDeclaration(
            'external Future<String> run(String stdin, String cmd, List<String> args);',
          ),
        ),
        isTrue,
      );
    });

    test('matches functions with required arguments as named', () {
      final signature = Signature('Future<String>', 'run', ['String cmd']);

      expect(
        signature.matches(
          _externalFunctionDeclaration(
            'external Future<String> run({required String cmd});',
          ),
        ),
        isTrue,
      );
    });

    test('does not match declarations with missing required parameters', () {
      final signature = Signature('Future<String>', 'run', [
        'String cmd',
        'List<String> args',
      ]);

      expect(
        signature.matches(
          _externalFunctionDeclaration(
            'external Future<String> run(String cmd);',
          ),
        ),
        isFalse,
      );

      expect(
        signature.matches(
          _externalFunctionDeclaration(
            'external Future<String> run(String cmd, [List<String> args]);',
          ),
        ),
        isFalse,
      );

      expect(
        signature.matches(
          _externalFunctionDeclaration(
            'external Future<String> run(String cmd, {List<String> args});',
          ),
        ),
        isFalse,
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

    test('parameterStringFor adds missing parameters as optional', () {
      final signature = Signature(
        'Future<String>',
        'run',
        ['String cmd'],
        ['List<String> args', 'String stdin'],
      );
      final function1 = _externalFunctionDeclaration(
        'external Future<String> run(String cmd);',
      );
      final function2 = _externalFunctionDeclaration(
        'external Future<String> run(String cmd, [String stdin]);',
      );
      final function3 = _externalFunctionDeclaration(
        'external Future<String> run(String cmd, {String stdin});',
      );

      expect(
        signature.parameterStringFor(ResolvedParameters.from(function1)),
        equals("String cmd, [List<String> args = const [], String stdin = '']"),
      );
      expect(
        signature.parameterStringFor(ResolvedParameters.from(function2)),
        equals("String cmd, [String stdin = '', List<String> args = const []]"),
      );
      expect(
        signature.parameterStringFor(ResolvedParameters.from(function3)),
        equals("String cmd, {String stdin = '', List<String> args = const []}"),
      );
    });

    test('parameterStringFor with no missing parameters', () {
      final signature = Signature('Future<String>', 'run', [
        'String cmd',
        'List<String> args',
        'String stdin',
      ]);
      final function = _externalFunctionDeclaration(
        'external Future<String> run(String cmd, List<String> args, {required String stdin});',
      );
      final resolved = ResolvedParameters.from(function);

      expect(
        signature.parameterStringFor(resolved),
        equals(resolved.toString(withDefaults: true)),
      );
    });
  });
}

FunctionDeclaration _externalFunctionDeclaration(String source) =>
    parseString(content: source).unit.declarations.single
        as FunctionDeclaration;
