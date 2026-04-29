# BoostDrive Automated Testing Model

This repository is a Flutter monorepo, so the primary test runner should be `flutter test` (or `melos run ...` wrappers), not Jest.

If you know Jest already, use this mental mapping:

- `describe/test/expect` in Jest == `group/test/expect` in Flutter tests.
- Jest unit tests == Dart/Flutter unit tests in `test/unit`.
- Jest component tests == Flutter widget tests in `test/widget`.
- Jest e2e tests (Playwright/Cypress style) == Flutter integration tests in `integration_test`.

## Recommended Test Pyramid

- **Unit tests (largest layer)**:
  - Models, parsing, mappers, helpers, derived/computed fields.
  - Business rules in services and notifiers.
  - Error-path behavior and fallback logic.
- **Widget/functional tests (medium layer)**:
  - Critical UI interactions (forms, dialogs, validation, status cards).
  - Riverpod provider state transitions in UI.
  - Regression tests for previously failed QA paths.
- **Integration tests (small layer)**:
  - App bootstrap + critical happy-path flows.
  - Cross-feature flow checks for SOS, checkout messaging, job cards, notifications.

## Folder Conventions

- `test/unit`: pure logic and model tests (fast, deterministic).
- `test/widget`: UI behavior tests.
- `integration_test`: end-to-end style tests for each app.

## Monorepo Commands (Melos)

- `melos run test` -> run all package tests.
- `melos run test:unit` -> run only `test/unit`.
- `melos run test:widget` -> run only `test/widget`.
- `melos run test:integration` -> run only `integration_test`.
- `melos run test:coverage` -> run tests with coverage.

## What Was Added Today

- Real unit tests for:
  - `SosRequest` parsing + live-status behavior (`boostdrive_core`).
  - `CartItem.totalPrice` logic (`boostdrive_services`).
  - `getInitials` helper (`boostdrive_ui`).
- Integration smoke test for Mobile app bootstrap in `apps/Mobile/integration_test`.
- Melos scripts for layered test execution.

## Next Tests To Add (High Priority)

- **SOS reliability**
  - Realtime-to-polling fallback stream tests (network drop simulation).
  - Active SOS status transitions and recovery checks.
- **Checkout/message seller flow**
  - Multi-seller checkout dialog selection and conversation creation behavior.
- **Job Card flow**
  - Quote lifecycle: request -> provider quote -> customer accept/decline.
- **Admin workflows**
  - Listing approval counters and ticket reply multiline behavior.
- **Navigation/map**
  - URL launch fallback snackbar and map rendering recovery on flaky network.

## CI Recommendation

For CI (GitHub Actions or similar), run in this order:

1. `melos bootstrap`
2. `melos run analyze`
3. `melos run test:unit`
4. `melos run test:widget`
5. `melos run test:integration` (on dedicated runners/devices)

This gives fast feedback first, with expensive tests last.
