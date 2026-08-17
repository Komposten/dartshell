import 'package:analyzer/dart/ast/ast.dart';
import 'package:meta/meta.dart';

/// Generates an implementation for one supported `external` function shape.
abstract class ExternalDeclarationProcessor {
  /// Whether the generated implementation uses `dart:io`.
  @nonVirtual
  final bool requiresDartIo;

  const ExternalDeclarationProcessor(this.requiresDartIo);

  String get description;

  List<Signature> signatures();

  /// Whether this processor owns [declaration]'s signature.
  @nonVirtual
  bool supports(FunctionDeclaration declaration) => signatures().any((signature) => signature.matches(declaration));

  /// The implementation that replaces [declaration].
  String implementationFor(FunctionDeclaration declaration);
}

class Signature {
  final String returnType;
  final String name;
  final String? requiredParameters;
  final String? positionalParameters;
  final String? namedParameters;
  late final String parameterList;
  late final List<String> _compactParameterLists;

  Signature(String returnType, String name, String? requiredParameters)
    : this._(returnType, name, requiredParameters, null, null);

  Signature.withPositional(String returnType, String name, String? requiredParameters, String? positionalParameters)
    : this._(returnType, name, requiredParameters, positionalParameters, null);

  Signature.withNamed(String returnType, String name, String? requiredParameters, String? namedParameters)
    : this._(returnType, name, requiredParameters, null, namedParameters);

  Signature._(this.returnType, this.name, this.requiredParameters, this.positionalParameters, this.namedParameters) {
    final bool hasRequired = requiredParameters != null;
    final bool hasPositional = positionalParameters != null;
    final bool hasNamed = namedParameters != null;

    if (hasPositional && hasNamed) {
      throw ArgumentError('Both positional and named parameters cannot be specified');
    }

    List<String> parameterLists;

    if (hasRequired) {
      parameterLists = [
        if (hasPositional) '($requiredParameters, [$positionalParameters])',
        if (hasNamed) '($requiredParameters, {$namedParameters})',
        '($requiredParameters)',
      ];
    } else {
      parameterLists = [if (hasPositional) '([$positionalParameters])', if (hasNamed) '({$namedParameters})', ''];
    }

    parameterList = parameterLists.first;
    _compactParameterLists = parameterLists.map(_compact).toList();
  }

  bool matches(FunctionDeclaration declaration) =>
      declaration.returnType?.toSource() == returnType &&
      declaration.name.lexeme == name &&
      _matchesParameterList(declaration.functionExpression.parameters?.toSource() ?? '');

  bool _matchesParameterList(String parameters) {
    var compact = _compact(parameters);
    return _compactParameterLists.any((e) => compact == e);
  }

  String _compact(String parameters) => parameters.replaceAll(RegExp(r'\s+'), '');

  @override
  String toString() => '$returnType $name$parameterList';
}
