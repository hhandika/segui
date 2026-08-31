# Repository Guidelines

## Project Structure & Module Organization

SEGUI is the Flutter GUI for SEGUL, a Rust toolkit for phylogenomic data manipulation and sequence summary statistics. Flutter calls Rust through Flutter Rust Bridge; keep core bioinformatics logic in the upstream `segul` dependency declared in `rust/Cargo.toml`.

- `lib/main.dart`: app startup, Rust initialization, preferences, and Riverpod setup.
- `lib/screens/`: feature UI grouped into `alignment/`, `sequence/`, `genomics/`, `home/`, `settings/`, and `viewers/`; reusable widgets and file-selection UI live in `shared/`.
- `lib/services/`: task orchestration in `tasks/`, Riverpod state in `providers/`, filesystem and logging helpers in `io/`, file parsing in `viewers/`, and shared controllers, types, and utilities.
- `lib/styles/`: themes in `themes.dart` and shared decorations and responsive breakpoints in `decoration.dart`.
- `rust/src/api/`: Rust bridge wrappers for alignment and sequence operations, contigs, reads, CSV, archives, and common utilities. Generated bindings live in `lib/src/rust/` and `rust/src/frb_generated*.rs`; configuration is in `flutter_rust_bridge.yaml`.
- `rust_builder/`: local Flutter FFI plugin and Cargokit integration for building the native Rust library.
- `test/`: Dart unit tests and fixtures in `test/files/`; `integration_test/` checks native startup, navigation, and bridge file IO, and `test_driver/` contains a currently commented-out integration driver. Rust unit tests are inline in the API modules, with fixtures in `rust/src/tests/`.
- `assets/`: illustrations in `images/`, app icons in `launcher/`, and bundled help in `markdown/`.
- `website/`: Docusaurus documentation and website; content is in `docs/` and `blog/`, React/TypeScript UI is in `src/`, and public assets are in `static/`.
- `android/`, `ios/`, `linux/`, `macos/`, and `windows/`: Native Flutter platform projects. Native Rust packaging is configured through `rust_builder/` for these five platforms; SEGUI does not target web browsers.
- `scripts.py` and `scripts/`: development and packaging helpers, including PowerShell scripts in `scripts/windows/`. `installer/` and `snap/` contain packaging configuration; `.github/workflows/` contains CI and release workflows.

## Build, Test, and Development Commands

Run Flutter and bridge commands from the repository root:

- `flutter pub get`: install Dart/Flutter dependencies.
- `flutter analyze`: analyze Dart code using `analysis_options.yaml`.
- `flutter test`: run unit and widget tests in `test/`.
- `dart run build_runner build --delete-conflicting-outputs`: regenerate Riverpod and Freezed code.
- `python3 scripts.py frb --generate`: regenerate native Rust/Dart bindings, run Freezed and Riverpod generation together, then apply scoped constructor fixes and formatting. Use generator 2.13.0 to match the bridge dependencies. The helper keeps generated providers intact and runs fixes after Freezed generation.
- `flutter run -d <device-id>`: run the app on a configured device.
- `flutter test integration_test -d <device-id>`: run startup, navigation, and file IO integration tests on a native target with the Rust library available.
- `cargo check`, `cargo clippy`, and `cargo test`: run from `rust/` to check, lint, and test the Rust crate.

For the documentation website, run `yarn install`, `yarn start`, `yarn typecheck`, or `yarn build` from `website/`. Inspect legacy helper scripts before running them: some clean generated files, upgrade dependencies, or install an older bridge generator.

## Coding Style & Naming Conventions

Use 2-space Dart formatting; run `dart format lib test integration_test test_driver`. Follow `flutter_lints` and the repository's `analysis_options.yaml`; `custom_lint` and `riverpod_lint` are available as development dependencies. Name Dart files in `snake_case.dart` and classes/widgets in `PascalCase`.

Always use cross-platform filesystem paths throughout application code, tests, and tooling, including fixtures, mocks, native-library paths, temporary files, and assertions. In Dart/Flutter, import `package:path/path.dart` as `p` and use `p.join`, `p.basename`, `p.dirname`, and `p.extension`. In Rust, use `std::path::Path` and `PathBuf`; use equivalent path APIs in other languages. Never concatenate or split filesystem path separators manually or hard-code `/tmp` or drive-letter paths. Create temporary directories through platform APIs such as `Directory.systemTemp.createTemp`, and clean up test directories in teardown. Code and tests intentionally handling Windows or POSIX path syntax must declare that syntax explicitly, such as with `p.Context(style: ...)`, instead of assuming the host platform.

## Rust Best Practices

Keep Rust code, comments, and docstrings to 100 characters per line; wrap long signatures cleanly. Follow `rustfmt` and Rust API Guidelines. Prefer `struct` plus `impl` over loose globals. In `impl` blocks, put `pub fn` methods first and private helpers last. Use `?`, pattern matching, references over clones, and no `.unwrap()` unless justified. Use `snake_case` for functions/variables, `PascalCase` for types/traits/enums, and `SCREAMING_SNAKE_CASE` for constants.

## Flutter Best Practices

Keep screens as thin UI wrappers under `lib/screens/`. Put business logic in `lib/services/` and reusable UI in `lib/screens/shared/`. Do not place UI in services or return widgets from helpers; create widget classes, no functions return widgets. In widget classes, only `@override` methods go before `build`; keep `build` near the top and helpers below. Prefer `const`, immutable models, and Riverpod over mutable globals. Keep `build` side-effect free; do filesystem, preferences, and bridge work in services/providers. Guard async UI updates with `context.mounted`. Use theme values.

Reuse the responsive breakpoints and decoration helpers in `lib/styles/decoration.dart`. Use the active `Theme.of(context)` and `ColorScheme` for colors and typography; add or update shared theme values in `lib/styles/themes.dart` when a value is not already available.

## Testing Guidelines

Add focused `*_test.dart` files in `test/`. Prefer service tests for file discovery, input/output handling, format detection, parsing, settings, and task validation; add widget tests for UI regressions. Run integration tests for startup, navigation, IO, or bridge changes, updating the existing scaffold as needed. Add Rust tests near the affected API module and keep fixtures in `rust/src/tests/`. CI currently runs `flutter analyze` and `flutter test` on Linux, Windows, and macOS.

## Agent-Specific Instructions

Preserve user changes and avoid unrelated refactors. Write the GUI product name as `SEGUI` and the underlying toolkit as `SEGUL`; Dart package imports use `package:segui/`. Agents must not create commits, branches, pushes, or pull requests; leave Git under user control. After bridge API edits, regenerate bindings and verify analysis plus `cargo check` and `cargo clippy`. Do not hand-edit generated bridge, Riverpod, or Freezed files. Add assets to `pubspec.yaml` only when needed.

Edit website documentation directly under `website/docs/` and bundled in-app help under `assets/markdown/`. Keep documentation aligned with the affected GUI or SEGUL behavior; do not edit generated website output or dependency directories.

`AGENTS.md` is the repository's single source of agent guidance; `CLAUDE.md` only imports it.
