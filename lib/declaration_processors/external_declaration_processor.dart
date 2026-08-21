import 'package:analyzer/dart/ast/ast.dart';
import 'package:dartshell/declaration_processors/resolved_parameters.dart';
import 'package:dartshell/declaration_processors/signature.dart';
import 'package:meta/meta.dart';

/// Generates an implementation for one supported `external` function shape.
abstract class ExternalDeclarationProcessor {
  /// Whether the generated implementation uses `dart:io`.
  @nonVirtual
  final bool requiresDartIo;

  const ExternalDeclarationProcessor(this.requiresDartIo);

  String get description;

  List<Signature> signatures();

  @nonVirtual
  Signature? signature(FunctionDeclaration declaration) => signatures()
      .where((signature) => signature.matches(declaration))
      .firstOrNull;

  /// Whether this processor owns [declaration]'s signature.
  @nonVirtual
  bool supports(FunctionDeclaration declaration) =>
      signature(declaration) != null;

  /// The implementation that replaces [declaration].
  @nonVirtual
  String implementationFor(FunctionDeclaration declaration) {
    final s = signature(declaration);

    if (s != null) {
      return implementationForSignature(
        s,
        ResolvedParameters.from(declaration),
      );
    }
    throw ArgumentError('$runtimeType does not support $declaration');
  }

  /// The implementation that replaces [signature].
  @protected
  String implementationForSignature(
    Signature signature,
    ResolvedParameters parameters,
  );
}
