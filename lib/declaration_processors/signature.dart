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
  String toString({bool highlighted = false}) {
    final optionalParameters = _optionalParameters.isNotEmpty
        ? '${_format(', [', _Ansi.dim, highlighted)}'
              '${_format(_optionalParameters.join(', '), _Ansi.parameter, highlighted)}'
              '${_format(']', _Ansi.dim, highlighted)}'
        : '';
    final requiredParameters = _format(
      _requiredParameters.join(', '),
      _Ansi.parameter,
      highlighted,
    );
    return '${_format(returnType, _Ansi.returnType, highlighted)} '
        '${_format(name, _Ansi.function, highlighted)}'
        '${_format('(', _Ansi.dim, highlighted)}'
        '$requiredParameters'
        '$optionalParameters'
        '${_format(')', _Ansi.dim, highlighted)}';
  }

  static String _format(String value, String color, bool highlighted) =>
      highlighted ? '$color$value${_Ansi.reset}' : value;
}

abstract final class _Ansi {
  static const reset = '\x1B[0m';
  static const dim = '\x1B[2m';
  static const returnType = '\x1B[36m';
  static const function = '\x1B[32m';
  static const parameter = '\x1B[33m';
}
