import 'package:analyzer/dart/ast/ast.dart';
import 'package:dartshell/declaration_processors/resolved_parameters.dart';

class Signature {
  final String returnType;
  final String name;
  final List<String> _parameters;
  final List<String> _compactParameters;

  Signature(String returnType, String name, List<String> parameters)
    : this._(returnType, name, parameters);

  Signature._(this.returnType, this.name, this._parameters)
    : _compactParameters = _parameters.map(_compact).toList();

  bool matches(FunctionDeclaration declaration) =>
      declaration.returnType?.toSource() == returnType &&
      declaration.name.lexeme == name &&
      _matchesParameterList(declaration);

  bool _matchesParameterList(FunctionDeclaration declaration) {
    final resolved = ResolvedParameters.from(declaration);

    for (final parameter in resolved.all) {
      var compact = _compact(parameter.short);
      if (!_compactParameters.contains(compact)) {
        return false;
      }
    }

    return true;
  }

  static String _compact(String value) => value.replaceAll(RegExp(r'\s+'), '');

  String parameterStringFor(ResolvedParameters resolvedParameters) {
    final unresolvedParameters = _getUnresolvedParameters(resolvedParameters);
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

  List<String> _getUnresolvedParameters(ResolvedParameters resolvedParameters) {
    final resolved = resolvedParameters.all.map((p) => p.short).toSet();
    return _parameters
        .where((p) => !resolved.contains(p))
        .map(ResolvedParameters.addDefault)
        .toList();
  }

  @override
  String toString() => '$returnType $name(${_parameters.join(', ')})';
}
