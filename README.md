# Dartshell

Write cross-platform, shell-like automation scripts in Dart without repeating `dart:io` process-handling boilerplate.

Dartshell makes it easy to compose Dart scripts that call external cli tools. Write scripts with the benefit of Dart linting and static analysis without having to worry about all boilerplate around `Process.run`.

Supports all major platforms.

<sub>**AI disclaimer:** GPT-5.6 Terra generated large portions of this code. It has been audited, tested and partly rewritten by me (@Komposten).</sub>

## Requirements

- Dart SDK `^3.12.2`

## Installation

```sh
dart install https://github.com/komposten/dartshell.git
dartshell --help
```

## Writing scripts

### Example

```dart
#!/usr/bin/env dartshell

// check_changes.dart, checks if any dart files have been changed in the repo
void main(List<String> args) async {
  final output = await run('git', ['status', '--short', ...args]);
  final files = output
      .split('\n')
      .map((l) {
        final trimmed = l.trim();
        final split = trimmed.split(RegExp(r'\s+'));
        return split.last;
      })
      .where((f) => f.endsWith('.dart'))
      .toList();

  if (files.isNotEmpty) {
    print('Detected dart file changes:');
    for (final file in files) {
      print('- $file');
    }
  } else {
    print('No dart files changed');
  }
}

external Future<String> run(String cmd, [List<String> args, String stdin]);
```

Execute it like any executable:

```sh
chmod +x check_changes.dart
./check_changes.dart --untracked-files=no
```

### Step-by-step
1. Create a new Dart file.
   - Run `dartshell --new <dart-file>` to create a Dart file pre-populated with a shebang, empty `main()` and a list of all Dartshell's `external` functions commented out at the end of the file. 
   - Or create a file manually with the following base content:
   ```dart
   #!/usr/bin/env dartshell
   
   void main(List<String> args) async {
     
   }
   ```
   In this case you have to manually define the `external` functions you want to use.\
   Run `dartshell --signatures` to get a list of supported functions.
3. Add your script code, calling the `external` functions like any normal Dart functions.

### External function declarations
You can obtain a list of Dartshell's supported `external` functions using `dartshell --signatures` or `dartshell --new`.

These function signatures are very flexible.

You may:
- Omit parameters you do not need
- Decide for each parameter whether it should be required or optional, as well as positional or named
- Add your own default values for optional parameters, or let Dartshell decide (it will use "empty" values: empty string, empty list, etc.).

You may not:
- Change the function and parameter names, the parameter types or the return type.

Here are a few examples of this flexibility:
```dart
// Original signature from `dartshell --signatures` or `dartshell --new`
external Future<String> run(String cmd, List<String> args, String stdin, bool silent);

// Examples of variants you could use:
external Future<String> run(String cmd);
external Future<String> run(String cmd, [List<String> args, String stdin]);
external Future<String> run(String cmd, List<String> args, {String stdin, bool silent = true});
external Future<String> run(String cmd, List<String> args, {required String stdin});
external Future<String> run(String cmd, String stdin, [List<String> args]);
```


## How it works
On its first run, Dartshell expands the `external` declarations, compiles the expanded script, and executes the resulting binary.
Subsequent runs reuse the binary until the source script changes, ensuring consistent performance after the first run.

### Technical details

Dartshell reads the script file, looks for any known `external` function signatures and replaces them with a concrete implementation.
The script is the compiled into a temporary directory (see below) using `dart compile exe` and executed from there.

The compiled binary will be reused on future invocations unless the original script changes.

`external` function declarations that are not recognised by Dartshell are left unchanged, so they may be used independently (for example, for FFI).

### Build cache

Generated sources and executables are cached in the system temporary directory:

```text
<system-temp>/dartshell/build/
<system-temp>/dartshell/bin/
```
