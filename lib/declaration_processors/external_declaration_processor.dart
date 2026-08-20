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
      return implementationForSignature(s);
    }
    throw ArgumentError('$runtimeType does not support $declaration');
  }

  /// The implementation that replaces [signature].
  @protected
  String implementationForSignature(Signature signature);
}

class Signature {
  final String returnType;
  final String name;
  final List<String> _requiredParameters;
  final List<String> _positionalParameters;
  final List<String> _namedParameters;
  late final String parameterList;
  late final List<String> _compactParameterLists;

  Signature(String returnType, String name, List<String> requiredParameters)
    : this._(returnType, name, requiredParameters, [], []);

  Signature.withPositional(
    String returnType,
    String name,
    List<String> requiredParameters,
    List<String> positionalParameters,
  ) : this._(returnType, name, requiredParameters, positionalParameters, []);

  Signature.withNamed(
    String returnType,
    String name,
    List<String> requiredParameters,
    List<String> namedParameters,
  ) : this._(returnType, name, requiredParameters, [], namedParameters);

  Signature._(
    this.returnType,
    this.name,
    this._requiredParameters,
    this._positionalParameters,
    this._namedParameters,
  ) {
    final bool hasRequired = _requiredParameters.isNotEmpty;

    if (hasPositionalParameters && hasNamedParameters) {
      throw ArgumentError(
        'Both positional and named parameters cannot be specified',
      );
    }

    List<String> parameterLists;

    final optional = optionalParameterList();
    if (hasRequired) {
      parameterLists = [
        if (optional != null) '($requiredParameterList, $optional)',
        '($requiredParameterList)',
      ];
    } else {
      parameterLists = [if (optional != null) '($optional)', '()'];
    }

    parameterList = parameterLists.first;
    _compactParameterLists = parameterLists.map(_compact).toList();
  }

  bool get hasPositionalParameters => _positionalParameters.isNotEmpty;
  bool get hasNamedParameters => _namedParameters.isNotEmpty;

  String get requiredParameterList => _requiredParameters.join(', ');
  String positionalParameterList({bool withDefaults = false}) =>
      '[${(withDefaults ? _addDefaults(_positionalParameters) : _positionalParameters).join(', ')}]';
  String namedParameterList({bool withDefaults = false}) =>
      '{${(withDefaults ? _addDefaults(_namedParameters) : _namedParameters).join(', ')}}';

  String? optionalParameterList({bool withDefaults = false}) =>
      hasPositionalParameters
      ? positionalParameterList(withDefaults: withDefaults)
      : hasNamedParameters
      ? namedParameterList(withDefaults: withDefaults)
      : null;

  static const _parameterDefaults = [
    (pattern: 'List<', defaultValue: 'const []'),
    (pattern: 'Map<', defaultValue: 'const {}'),
    (pattern: 'Set<', defaultValue: 'const {}'),
    (pattern: 'String ', defaultValue: "''"),
  ];

  Iterable<String> _addDefaults(Iterable<String> parameters) => parameters.map((
    parameter,
  ) {
    final value = _parameterDefaults
        .where((entry) => parameter.startsWith(entry.pattern))
        .firstOrNull
        ?.defaultValue;
    if (value != null) {
      return '$parameter = $value';
    } else {
      throw ArgumentError('No default declared for parameter type: $parameter');
    }
  });

  bool matches(FunctionDeclaration declaration) =>
      declaration.returnType?.toSource() == returnType &&
      declaration.name.lexeme == name &&
      _matchesParameterList(
        declaration.functionExpression.parameters?.toSource() ?? '',
      );

  bool _matchesParameterList(String parameters) {
    var compact = _compact(parameters);
    return _compactParameterLists.any((e) => compact == e);
  }

  String _compact(String parameters) =>
      parameters.replaceAll(RegExp(r'\s+'), '');

  @override
  String toString() => '$returnType $name$parameterList';
}
