import 'package:analyzer/dart/ast/ast.dart';

/// Generates an implementation for one supported `external` function shape.
abstract interface class ExternalDeclarationProcessor {
  /// Whether this processor owns [declaration]'s signature.
  bool supports(FunctionDeclaration declaration);

  /// The implementation that replaces [declaration].
  String implementationFor(FunctionDeclaration declaration);

  /// Whether the generated implementation uses `dart:io`.
  bool get requiresDartIo;
}
