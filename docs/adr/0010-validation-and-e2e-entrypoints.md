# ADR 0010: Validate with Flutter unit tests plus web/E2E Hermes entry points

Status: accepted
Date: 2026-07-07

## Context

The README and CI workflow define the practical validation surface: Flutter analyze, serialized Flutter tests, web E2E builds through `lib/main_e2e.dart`, Playwright Hermes smoke tests, and platform builds. `main_e2e.dart` exposes JavaScript hooks that drive Hermes connect/session/send/voice behavior through the real app router and provider seam.

## Decision

Use layered validation:

1. `flutter analyze` for static checks.
2. `flutter test --concurrency=1` for deterministic Dart/Flutter behavior tests.
3. `flutter build web --release -t lib/main_e2e.dart` for browser/E2E build compatibility.
4. Playwright smoke tests for browser-visible Hermes behavior.
5. Platform builds/smokes in CI where runner dependencies are available.

## Consequences

- New behavior should leave a focused test at the same seam callers use when feasible.
- E2E-only hooks belong in `main_e2e.dart`, not production app startup.
- Local Linux builds require host packages such as `libsecret-1-dev`; CI installs them before Linux build.

## Edge cases

- Web E2E tests use JavaScript hooks from `main_e2e.dart`; production `main.dart` must not expose those hooks.
- Live/provider smokes must not print API keys or require checked-in credentials.
- A local Linux build can fail on missing host packages even when Dart tests and web builds pass.

## Evidence

- `README.md:39-46`
- `package.json:10-23`
- `.github/workflows/hermes-platform-smoke.yml:46-83`
- `.github/workflows/hermes-platform-smoke.yml:123-147`
- `lib/main_e2e.dart:14-58`
- `playwright.config.mjs:1-28`
