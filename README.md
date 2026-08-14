# Dartshell

Write cross-platform, shell-like automation scripts in Dart without repeating `dart:io` process-handling boilerplate.

Dartshell makes it easy to compose Dart scripts that call external cli tools. Write scripts with the benefit of Dart linting and static analysis without having to worry about all boilerplate around `Process.run`.

Supports all major platforms.

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
Future<void> main(List<String> args) async {
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

external Future<String> run(String cmd, [List<String> args]);
```

Execute it like any executable:

```sh
chmod +x check_changes.dart
./check_changes.dart --untracked-files=no
```

### Step-by-step
1. Create a new Dart file:
   ```dart
   #!/usr/bin/env dartshell
   
   void main(List<String> args) {
     
   }
   ```
2. Define one of Dartshell's `external` functions at the end of the file:
   - `run`: Runs `cmd` with the specified arguments
     - `external Future<String> run(String cmd, List<String> args);`
     - `external Future<String> run(String cmd, [List<String> args]);`
3. Add your script code, calling the `external` functions like any normal Dart functions.

Write your Dart

## How it works
On its first run, Dartshell expands the `external` declaration, compiles the expanded script, and executes the resulting binary.
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
