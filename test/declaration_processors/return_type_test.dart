import 'package:dartshell/declaration_processors/return_type.dart';
import 'package:test/test.dart';

void main() {
  group('ReturnType', () {
    test('maps supported return type signatures to their values', () {
      expect(ReturnType.stdout.signature, 'Future<String>');
      expect(ReturnType.stdoutStderr.signature, 'Future<(String, String)>');
      expect(ReturnType.of('Future<String>'), ReturnType.stdout);
      expect(
        ReturnType.of('Future<(String, String)>'),
        ReturnType.stdoutStderr,
      );
    });
  });
}
