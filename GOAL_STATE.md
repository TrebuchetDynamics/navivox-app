# GOAL STATE — 2026-06-16

## Status

The 14-slice gateway-wiring goal that drove this file is **complete**. The
five blockers it tracked were all "wire X" tasks against the Navivox gateway
channel/presentation layer; each is now either implemented or no longer
present in the code.

## Verified gate (2026-06-16)

- `flutter analyze` — no issues.
- `flutter test --concurrency=1` — **896 tests pass** (includes a new
  regression test for gateway stream-close send rejection).

These are the authoritative, reproducible signals for the app today. The
Playwright e2e/screenshot suites under `playwright/tests/` still exist
(`navivox-e2e.spec.mjs`, `e2e-screenshots.spec.mjs`) but were not re-run for
this update; rerun them against a web build when a visual-coverage refresh is
needed.

## Former "next actions" — resolution

The prior next-action list referenced symbols that no longer exist or are
already wired (verified by grep over `lib/**.dart` on 2026-06-16):

1. `connectIntentSource` — wired in `lib/features/servers/screens/setup_screen.dart`
   (initial + foreground import, auto-connect/confirmation gating via the
   pairing-handoff flow).
2. `_selectedProfileSegments.removeListener` — symbol absent; chat read-state
   listener handling was reworked.
3. `refreshGateways` — symbol absent; server gateway refresh handled elsewhere.
4. `memorySearchUnavailableMessage` — symbol absent; degrade copy reworked.
5. `settingsUnavailableMessage` — symbol absent; disabled-settings copy reworked.

No action remains from this list.

## Remaining open work

Tracked in `TODO.md`. The live `[PLANNED]` / `[BLOCKED]` items are **not
actionable from the app side alone** — they wait on external dependencies:

- **Durable connection credential storage** — needs the Gormes gateway to
  advertise the device-credential issuance/rotation/revoke protocol.
- **Approval response protocol** — needs Gormes to advertise a stable
  approve/deny action or endpoint.
- **Composer attachment upload / media picker** — needs Gormes to advertise
  `/v1/navivox/uploads` with opaque upload IDs and a MIME allowlist.
- **Android pairing-handoff + continuous-voice live smoke** — needs a
  responsive physical/emulated Android target on the test host.

## Acceptance audit

The 14-slice goal is closed. The next goal should be framed around whichever
external dependency above lands first (Gormes endpoint advertisement or a
responsive Android target), at which point the corresponding `TODO.md` item
becomes actionable and a fresh goal slice can be defined.
