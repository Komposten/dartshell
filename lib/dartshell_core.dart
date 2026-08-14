import 'dart:io';
import 'package:dartshell/bool_extensions.dart';
import 'package:dartshell/script_preprocessor.dart';
import 'package:path/path.dart' as path;

Future<int> run(String scriptPath, List<String> args, {bool verbose = false}) async {
  final scriptFile = File(scriptPath);
  if (!await scriptFile.exists() || (await scriptFile.stat()).type != FileSystemEntityType.file) {
    throw '$scriptPath does not exist or is not a file';
  }

  final buildDir = Directory(path.join(Directory.systemTemp.path, 'dartshell', 'build'));
  final binDir = Directory(path.join(Directory.systemTemp.path, 'dartshell', 'bin'));
  final buildName = '${path.basename(scriptPath)}-${scriptFile.absolute.path.hashCode}';
  final buildPath = path.join(buildDir.path, buildName);
  final binPath = path.join(binDir.path, buildName);

  if (await _shouldRecompile(scriptPath, buildPath)) {
    verbose.ifTrue(() => print('Patching $scriptPath to $buildPath'));
    await _expandRunnables(scriptPath, buildPath);

    verbose.ifTrue(() => print('Compiling $buildPath to $binPath'));
    await binDir.create(recursive: true);
    final compilation = await Process.run('dart', ['compile', 'exe', buildPath, '--output', '$binPath']);
    if (compilation.exitCode != 0) {
      throw 'Failed to compile Dart script: ${compilation.stderr}';
    }
  }

  verbose.ifTrue(() => print('Executing command: $binPath ${args.join(' ')}'));

  final execution = await Process.start(binPath, args, mode: ProcessStartMode.inheritStdio);
  final exitCode = await execution.exitCode;

  verbose.ifTrue(() => print('Command exited with code $exitCode'));

  return exitCode;
}

Future<bool> _shouldRecompile(String scriptPath, String buildPath) async {
  final buildFile = File(buildPath);
  if (!await buildFile.exists()) {
    return true;
  }

  final scriptModified = await File(scriptPath).lastModified();
  final buildModified = await buildFile.lastModified();
  return scriptModified.isAfter(buildModified);
}

Future<void> _expandRunnables(String scriptPath, String buildPath) async {
  final scriptFile = File(scriptPath);
  final script = await scriptFile.readAsString();

  final expandedScript = _expand(script);

  final buildFile = File(buildPath);
  await buildFile.create(recursive: true);
  await buildFile.writeAsString(expandedScript);
}

String _expand(String script) {
  return ScriptPreprocessor().preprocess(script);
}
