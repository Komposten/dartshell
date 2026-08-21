import 'package:analyzer/dart/ast/ast.dart';
import 'package:dartshell/declaration_processors/resolved_parameters.dart';

class Signature {
  final String returnType;
  final String name;
  final List<String> _requiredParameters;
  final List<String> _optionalParameters;
  final List<String> _compactParameters;

  Signature(
    this.returnType,
    this.name,
    List<String> requiredParameters, [
    List<String> optionalParameters = const [],
  ]) : _requiredParameters = requiredParameters,
       _optionalParameters = optionalParameters,
       _compactParameters = requiredParameters
           .followedBy(optionalParameters)
           .map(_compact)
           .toList();

  bool matches(FunctionDeclaration declaration) =>
      declaration.returnType?.toSource() == returnType &&
      declaration.name.lexeme == name &&
      _matchesParameterList(ResolvedParameters.from(declaration));

  bool _matchesParameterList(ResolvedParameters resolved) {
    // Verify all required parameters are present in `resolved`
    for (final required in _requiredParameters) {
      final compact = _compact(required);
      if (resolved.all.every(
        (p) => !p.required || _compact(p.short) != compact,
      )) {
        return false;
      }
    }

    // Verify all resolved parameters are valid for this signature
    for (final parameter in resolved.all) {
      final compact = _compact(parameter.short);
      if (!_compactParameters.contains(compact)) {
        return false;
      }
    }

    return true;
  }

  static String _compact(String value) => value.replaceAll(RegExp(r'\s+'), '');

  String parameterStringFor(ResolvedParameters resolvedParameters) {
    if (!_matchesParameterList(resolvedParameters)) {
      throw ArgumentError(
        'The resolved parameters do not match the expected parameters',
      );
    }

    final unresolvedParameters = _getUnresolvedOptionalParameters(
      resolvedParameters,
    );
    final resolvedRequired = resolvedParameters.requiredAsString;
    final resolvedOptional =
        resolvedParameters.optionalAsString(withDefaults: true) ?? '';

    String patchedOptional;
    if (unresolvedParameters.isNotEmpty) {
      final withDefaults = unresolvedParameters.join(', ');
      if (resolvedOptional.isNotEmpty) {
        patchedOptional =
            '${resolvedOptional.substring(0, resolvedOptional.length - 1)}, $withDefaults${resolvedOptional.substring(resolvedOptional.length - 1)}';
      } else {
        patchedOptional = '[$withDefaults]';
      }
    } else {
      patchedOptional = resolvedOptional;
    }

    if (resolvedRequired.isNotEmpty && patchedOptional.isNotEmpty) {
      return '$resolvedRequired, $patchedOptional';
    } else if (resolvedRequired.isNotEmpty) {
      return resolvedRequired;
    } else {
      return patchedOptional;
    }
  }

  List<String> _getUnresolvedOptionalParameters(
    ResolvedParameters resolvedParameters,
  ) {
    final resolved = resolvedParameters.all.map((p) => p.short).toSet();
    return _optionalParameters
        .where((p) => !resolved.contains(p))
        .map(ResolvedParameters.addDefault)
        .toList();
  }

  @override
  String toString() {
    final optionalParameters = _optionalParameters.isNotEmpty
        ? ', [${_optionalParameters.join(', ')}]'
        : '';
    final requiredParameters = _requiredParameters.join(', ');
    return '$returnType $name($requiredParameters$optionalParameters)';
  }
}
