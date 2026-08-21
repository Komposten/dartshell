import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dartshell/declaration_processors/resolved_parameters.dart';
import 'package:test/test.dart';

void main() {
  group('ResolvedParameters', () {
    test('resolves required parameters', () {
      final parameters = ResolvedParameters.from(
        _functionDeclaration('void run(String command, int retries) {}'),
      );

      expect(parameters.required, [
        (
          source: 'String command',
          short: 'String command',
          required: true,
          hasDefault: false,
        ),
        (
          source: 'int retries',
          short: 'int retries',
          required: true,
          hasDefault: false,
        ),
      ]);
      expect(parameters.positional, isEmpty);
      expect(parameters.named, isEmpty);
      expect(parameters.requiredAsString, 'String command, int retries');
      expect(parameters.optionalAsString(), isNull);
      expect(parameters.toString(), 'String command, int retries');
    });

    test('resolves and renders optional positional parameters', () {
      final parameters = ResolvedParameters.from(
        _functionDeclaration(
          'void run(String command, [List<String> arguments, int retries = 3]) {}',
        ),
      );

      expect(parameters.positional, [
        (
          source: 'List<String> arguments',
          short: 'List<String> arguments',
          required: false,
          hasDefault: false,
        ),
        (
          source: 'int retries = 3',
          short: 'int retries',
          required: false,
          hasDefault: true,
        ),
      ]);
      expect(
        parameters.positionalAsString(),
        '[List<String> arguments, int retries = 3]',
      );
      expect(
        parameters.positionalAsString(withDefaults: true),
        '[List<String> arguments = const [], int retries = 3]',
      );
      expect(
        parameters.toString(withDefaults: true),
        'String command, [List<String> arguments = const [], int retries = 3]',
      );
    });

    test('resolves and renders named parameters', () {
      final parameters = ResolvedParameters.from(
        _functionDeclaration(
          "void run({required String command, String label, Map<String, int> environment, Set<String> tags, String output = 'stdout'}) {}",
        ),
      );

      expect(parameters.named, [
        (
          source: 'required String command',
          short: 'String command',
          required: true,
          hasDefault: false,
        ),
        (
          source: 'String label',
          short: 'String label',
          required: false,
          hasDefault: false,
        ),
        (
          source: 'Map<String, int> environment',
          short: 'Map<String, int> environment',
          required: false,
          hasDefault: false,
        ),
        (
          source: 'Set<String> tags',
          short: 'Set<String> tags',
          required: false,
          hasDefault: false,
        ),
        (
          source: "String output = 'stdout'",
          short: 'String output',
          required: false,
          hasDefault: true,
        ),
      ]);
      expect(
        parameters.namedAsString(withDefaults: true),
        "{required String command, String label = '', Map<String, int> environment = const {}, Set<String> tags = const {}, String output = 'stdout'}",
      );
      expect(
        parameters.toString(withDefaults: true),
        "{required String command, String label = '', Map<String, int> environment = const {}, Set<String> tags = const {}, String output = 'stdout'}",
      );
    });

    test(
      'throws when no inferred default exists for an optional parameter',
      () {
        final parameters = ResolvedParameters.from(
          _functionDeclaration('void run([int retries]) {}'),
        );

        expect(
          () => parameters.positionalAsString(withDefaults: true),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.message,
              'message',
              'No default declared for parameter type: int retries',
            ),
          ),
        );
      },
    );
  });
}

FunctionDeclaration _functionDeclaration(String source) =>
    parseString(content: source).unit.declarations.single
        as FunctionDeclaration;
