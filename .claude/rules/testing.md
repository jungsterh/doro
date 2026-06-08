---
name: testing
description: Test conventions and eval workflow for Doro
paths: ["test/**/*.dart", "integration_test/**/*.dart"]
---

# Testing Rules

## Test Structure
Mirror `lib/` exactly under `test/`:
- `test/services/` — service unit tests with mocked Supabase
- `test/providers/` — Riverpod provider tests
- `test/models/` — model serialization/logic tests
- `test/core/` — utility tests
- `integration_test/` — full app integration tests (run on device/emulator)

## Mocking
Use `mockito` with `@GenerateMocks` annotation + `build_runner`:
```dart
@GenerateMocks([SupabaseClient, DatabaseService])
void main() { ... }
```
Run `dart run build_runner build` after changing mock targets.

## Eval Workflow (Run After Every Change)
```bash
flutter analyze          # must be clean — zero warnings/errors
flutter test             # all unit/widget tests green
flutter test integration_test/  # integration suite (requires emulator)
```

If a test needs to be temporarily skipped:
```dart
// TODO: re-enable after <condition>
skip: 'reason'
```
Never delete a test to make the suite pass — fix the underlying issue.

## What to Test
- Every public method in `lib/services/` should have a corresponding test
- Providers: test state transitions, not implementation details
- Models: test `fromJson`/`toJson` round-trips
- Widgets: test that they render without error and respond to user interaction

## What NOT to Test
- Private methods (test behavior through the public API)
- Flutter framework internals
- Third-party package behavior
