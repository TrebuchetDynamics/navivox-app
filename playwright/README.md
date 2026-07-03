# Navivox Playwright E2E Tests

End-to-end tests for the Navivox Flutter web app, using Playwright to interact
with the Flutter web accessibility/semantics tree.

## Prerequisites

- Flutter SDK 3.38+
- Node.js 22+
- Playwright (installed via `npm install`)
- Built Flutter web e2e bundle: `flutter build web --release -t lib/main_e2e.dart`

## Quick Start

```bash
# Build the e2e test app
flutter build web --release -t lib/main_e2e.dart

# Serve and test
node serve_web.mjs &
npx playwright test --config=playwright.config.mjs
kill %1

# Or use the script
./playwright/scripts/run_tests.sh
```

## Layout

```text
playwright/
├── tests/
│   ├── regression/   # Core app E2E specs run by playwright.config.mjs
│   └── screenshots/  # Screenshot/back-nav specs run by playwright.config.mjs
├── support/          # Shared Flutter semantics helpers for specs and probes
├── debug/            # One-off browser/debug scripts
├── probes/           # Exploratory route and surface probes
├── scripts/          # Runnable helpers
└── screenshots/      # Generated local screenshots, ignored by git
```

## Test Coverage (92 listed Playwright tests)

Current count comes from `npx playwright test --config=playwright.config.mjs --list`.
The default local suite includes deterministic fake-Hermes coverage; two live
Hermes specs are env-gated and skipped unless their endpoint variables are set.
Passing browser tests are useful receipts, but they are not platform-readiness
completion evidence by themselves; use `docs/runbooks/hermes-readiness-audit.md`
for the current blocker list.

| Area | Tests | Verifies |
|------|-------|----------|
| **Hermes fake browser smoke** | 2 | `/hermes` connect form, setup hints, fake Hermes HTTP/SSE transport, sessions, capabilities, catalogs/jobs, approvals, stop, text turns, and device-transcript voice submission |
| **Hermes live/API smoke** | 1 env-gated | Installed Hermes Agent API connection and session drawer rendering via `NAVIVOX_LIVE_HERMES_URL` |
| **Hermes provider chat/voice smoke** | 1 env-gated | Provider-backed text and device-transcript voice prompts via `NAVIVOX_PROVIDER_HERMES_URL`; this does not replace physical Android microphone receipts |
| **Legacy Gormes regression flow** | 66 | Preserved profile/gateway/chat/menu/memory/config/settings/setup/config-admin behavior in `navivox-e2e.spec.mjs` |
| **Screenshot/back-navigation coverage** | 22 | Route back behavior, gateway/profile detail surfaces, mobile transcript actions, and screenshot inventory |

## Architecture

The e2e build (`lib/main_e2e.dart`) uses both Hermes and preserved Gormes test
surfaces:

- `E2EMockChannel` implements the legacy `NavivoxChannel` with seeded Gormes
  gateways/profiles and echo chat behavior for preserved regression routes.
- `serve_web.mjs` exposes a fake Hermes HTTP/SSE API for deterministic browser
  tests, and `globalThis.navivoxE2EHermesConnect`/send helpers drive the real
  `HermesApiChannel` web transport.
- Live Hermes specs use explicit environment variables and are skipped by
  default so local runs do not require provider secrets.

Flutter web renders via CanvasKit (no DOM widgets). Tests interact through the
**accessibility semantics tree** — parallel `flt-semantics` elements with ARIA
roles, labels, and text content.

### Click approach

Buttons use `role="button"` with text content; popup menu items use
`role="menuitem"` with `aria-label`. All clicks dispatch
`PointerEvent` + `MouseEvent` sequences directly on the semantics element.

### Limitations

- CanvasKit requires WebGL which may not work in headless Chrome.
  Tests validate DOM/accessibility state, not pixel output.
- Flutter stores input values in `TextEditingController` (internal state),
  not the native `<input>`/`<textarea>` DOM value. `page.fill()` and
  programmatic value setters don't propagate to Flutter's state.
  Tests verify navigation and element presence, not text entry.
- Popup menu items (`role="menuitem"`) use `aria-label` not text content.