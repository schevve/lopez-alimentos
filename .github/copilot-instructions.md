# Cesta Básica Lopes

Read the [README](../README.md) for product context and the intended mobile-app features. Keep changes focused on the requested behavior and preserve unrelated work already present in the working tree.

## Repository Map

- `app/cesta_flow/` is the Flutter package root. Run Flutter and Dart commands from this directory.
- `app/cesta_flow/lib/main.dart` is the app entry point and defines the initial screen and named routes.
- `app/cesta_flow/lib/features/<feature>/presentation/` contains feature screens and form flows. Existing feature areas include `customer`, `sale`, `payment`, and `dashboard`.
- `app/cesta_flow/lib/core/data/local/` contains SQLite setup, models, and repositories. Keep database column names, model mapping, and repository queries consistent.
- `supabase/` is reserved for backend migrations and seeds; consult the existing files before changing the backend contract.
- Do not edit `build/`, generated plugin files, or platform build output unless the task explicitly targets platform configuration.

## Development Workflow

From `app/cesta_flow/`:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Run `dart format lib test` after Dart changes when the `test/` directory exists. Add or update focused Flutter tests for behavior changes; do not treat a successful build as a substitute for tests.

## Code Conventions

- Follow the existing Flutter/Dart style and `analysis_options.yaml` based on `flutter_lints`.
- Prefer package imports such as `package:cesta_flow/...` for project code.
- Keep UI code in feature presentation folders and persistence details behind repositories rather than querying SQLite from widgets.
- Use the existing model `toMap`/`fromMap` pattern for local persistence. Database schema changes must include an appropriate version and upgrade path in `db_helper.dart`.
- Preserve Portuguese user-facing text and domain terminology unless the task requests localization or a wording change.
- Keep public APIs and existing route names stable unless the requested change requires otherwise.

## Collaboration

- Commit messages should be written in Portuguese.
- Before editing, inspect the relevant nearby implementation and tests. Validate the smallest affected slice first, then run the broader checks when practical.
- Do not commit changes or revert unrelated user modifications.
