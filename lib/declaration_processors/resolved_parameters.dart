import 'package:analyzer/dart/ast/ast.dart';

typedef Parameter = ({
  String source,
  String short,
  bool required,
  bool hasDefault,
});

class ResolvedParameters {
  final List<Parameter> required;
  final List<Parameter> positional;
  final List<Parameter> named;

  Iterable<Parameter> get all =>
      required.followedBy(positional).followedBy(named);

  ResolvedParameters._(this.required, this.positional, this.named);

  factory ResolvedParameters.from(FunctionDeclaration declaration) {
    final required = <Parameter>[];
    final positional = <Parameter>[];
    final named = <Parameter>[];

    final parameters =
        declaration.functionExpression.parameters?.parameters ??
        <FormalParameter>[];
    for (final parameter in parameters) {
      final source = parameter.toSource();
      final short = '${parameter.type} ${parameter.name}';
      if (parameter.isNamed) {
        named.add((
          source: source,
          short: short,
          required: parameter.isRequired,
          hasDefault: parameter.defaultClause != null,
        ));
      } else if (parameter.isOptionalPositional) {
        positional.add((
          source: source,
          short: short,
          required: false,
          hasDefault: parameter.defaultClause != null,
        ));
      } else {
        required.add((
          source: source,
          short: short,
          required: true,
          hasDefault: false,
        ));
      }
    }

    return ResolvedParameters._(
      List.unmodifiable(required),
      List.unmodifiable(positional),
      List.unmodifiable(named),
    );
  }

  @override
  String toString({bool withDefaults = false}) {
    final required = requiredAsString;
    final optional = optionalAsString(withDefaults: withDefaults) ?? '';

    if (optional.isEmpty) {
      return required;
    } else if (required.isEmpty) {
      return optional;
    } else {
      return '$required, $optional';
    }
  }

  String get requiredAsString => required.map((p) => p.source).join(', ');

  String positionalAsString({bool withDefaults = false}) =>
      '[${positional.map((p) => withDefaults && !p.hasDefault ? addDefault(p.source) : p.source).join(', ')}]';

  String namedAsString({bool withDefaults = false}) =>
      '{${named.map((p) => withDefaults && !p.required && !p.hasDefault ? addDefault(p.source) : p.source).join(', ')}}';

  String? optionalAsString({bool withDefaults = false}) => positional.isNotEmpty
      ? positionalAsString(withDefaults: withDefaults)
      : named.isNotEmpty
      ? namedAsString(withDefaults: withDefaults)
      : null;

  static const _parameterDefaults = [
    (pattern: 'List<', defaultValue: 'const []'),
    (pattern: 'Map<', defaultValue: 'const {}'),
    (pattern: 'Set<', defaultValue: 'const {}'),
    (pattern: 'String ', defaultValue: "''"),
    (pattern: 'bool ', defaultValue: 'false'),
  ];

  static String addDefault(String parameter) {
    final value = _parameterDefaults
        .where((entry) => parameter.startsWith(entry.pattern))
        .firstOrNull
        ?.defaultValue;
    if (value != null) {
      return '$parameter = $value';
    } else {
      throw ArgumentError('No default declared for parameter type: $parameter');
    }
  }
}
