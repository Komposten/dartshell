import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

import 'declaration_processors/external_declaration_processor.dart';
import 'declaration_processors/run_external_declaration_processor.dart';

export 'declaration_processors/external_declaration_processor.dart';
export 'declaration_processors/run_external_declaration_processor.dart';

/// The processors available to Dartshell scripts and CLI commands.
const defaultExternalDeclarationProcessors = <ExternalDeclarationProcessor>[
  RunExternalDeclarationProcessor(),
];

/// Transforms supported external declarations in a Dart script into their
/// self-contained implementations.
///
/// Add a new [ExternalDeclarationProcessor] to [processors] to support another
/// declaration signature without changing the parsing or source-edit logic.
class ScriptPreprocessor {
  ScriptPreprocessor() : _processors = defaultExternalDeclarationProcessors;

  final List<ExternalDeclarationProcessor> _processors;

  /// Returns [script] with every supported external declaration implemented.
  ///
  /// Unsupported declarations are intentionally left unchanged. This lets a
  /// script use unrelated `external` declarations, for example for FFI.
  String preprocess(String script) {
    final unit = parseString(content: script).unit;
    final edits = <_SourceEdit>[];
    var needsDartIo = false;

    for (final declaration in unit.declarations) {
      if (declaration is! FunctionDeclaration ||
          declaration.externalKeyword == null) {
        continue;
      }

      final processor = _processors
          .cast<ExternalDeclarationProcessor?>()
          .firstWhere(
            (processor) => processor!.supports(declaration),
            orElse: () => null,
          );
      if (processor == null) {
        continue;
      }

      edits.add(
        _SourceEdit(
          offset: declaration.offset,
          length: declaration.length,
          replacement: processor.implementationFor(declaration),
        ),
      );
      needsDartIo |= processor.requiresDartIo;
    }

    if (edits.isEmpty) {
      return script;
    }

    if (needsDartIo && !_hasDartIoImport(unit)) {
      final insertionOffset = _dartIoImportInsertionOffset(unit);
      edits.add(
        _SourceEdit(
          offset: insertionOffset,
          length: 0,
          replacement: _dartIoImportAt(unit, insertionOffset),
        ),
      );
    }

    return _applyEdits(script, edits);
  }

  static bool _hasDartIoImport(CompilationUnit unit) => unit.directives
      .whereType<ImportDirective>()
      .any((directive) => directive.uri.stringValue == 'dart:io');

  static int _dartIoImportInsertionOffset(CompilationUnit unit) {
    final firstPart = unit.directives.whereType<PartDirective>().firstOrNull;
    if (firstPart != null) {
      return firstPart.offset;
    }

    if (unit.directives.isNotEmpty) {
      return unit.directives.last.end;
    }

    return unit.scriptTag?.end ?? 0;
  }

  static String _dartIoImportAt(CompilationUnit unit, int offset) {
    if (offset == 0) {
      return "import 'dart:io';\n\n";
    }

    final isBeforePart = unit.directives.whereType<PartDirective>().any(
      (directive) => directive.offset == offset,
    );
    return isBeforePart ? "import 'dart:io';\n" : "\nimport 'dart:io';";
  }

  static String _applyEdits(String source, List<_SourceEdit> edits) {
    edits.sort((a, b) => b.offset.compareTo(a.offset));
    var result = source;
    for (final edit in edits) {
      result = result.replaceRange(
        edit.offset,
        edit.offset + edit.length,
        edit.replacement,
      );
    }
    return result;
  }
}

class _SourceEdit {
  const _SourceEdit({
    required this.offset,
    required this.length,
    required this.replacement,
  });

  final int offset;
  final int length;
  final String replacement;
}
