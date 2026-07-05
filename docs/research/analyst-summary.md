# Analyst Summary — Navivox App Playwright E2E

Status: historical 2026-05 Gormes Playwright analyst note. Current Hermes-first
browser/readiness status lives in [Hermes platform smoke checklist](../runbooks/hermes-platform-smoke.md)
and [Hermes companion readiness audit](../runbooks/hermes-readiness-audit.md).
As of 2026-07-05, browser/provider receipts and the published platform workflow
are covered separately: `npm run hermes:provider-smoke:local` writes the
current-head provider text/transcript-voice receipt, and
`npm run platform:workflow-smoke` writes the current-head Windows/iOS/macOS
native-host workflow receipt. Broad platform readiness still depends on a real
Android physical-audio receipt and deferred Hermes parity/server-audio decisions.

## Session metadata
- APP_URL = http://127.0.0.1:8767/
- sessionDate = 2026-05-21 10:00 CST
- owner = Juan

## Results

### Historical E2E Test Counts (`navivox-e2e.spec.mjs`)
- 43 specs passed in this 2026-05 Gormes report
- 12 screenshot specs were added later under `playwright/tests/screenshots/e2e-screenshots.spec.mjs`
- Historical valid coverage at this point: 55 checks

### Historical Screenshot Inventory (55 unique captures)
#### Gateway coverage (14e-g)
  14c gateway list, 14d admin detail, 14e register modal, 14f voice agent gateway, 14g gateway setup screen

#### Back Navigation (12a-k)
  12a chat back, 12b server back, 12c agents back, 12d memory back, 12e config back
  12f settings back, 12g server detail back, 12h profile gateways back, 12i forward back
  12j memory sheet back, 12k external link back

#### Mobile Transcript (11h-k)
  11h transcript menu, 11i menu items, 11j transcript view, 11k transcript run

#### Extra Nav Tiles (12l-o)
  12l gateway list nav, 12m gateway admin health, 12n contact detail, 12o chat detail

### Historical Blocker Specs (5 not-passing in this 2026-05 run)
  1h gateway register: `_connectIntentSubscription?.cancel()` not wired
  2b chat read state: `_profileSelectedSegments.removeListener(_onChannelChanged)` not wired
  5a servers gateway: `_serversPresentation.refreshGateways` not dispatched
  5d memory degraded: `_memoryPresentation.memorySearchUnavailableMessage` not dispatched
  5e settings disabled: `_settingsPresentation.settingsUnavailableMessage` not dispatched

### Historical Status & Next

- Historical 2026-05 Gormes UI goal remained active at this point (55 coverage points, 5 blockers unresolved).
- That status is not the current Hermes readiness status. Use the runbooks linked at the top of this file for current blockers and completion criteria.
- Historical next step was gateway-admin dispatch wiring: connect intent source, profile read state listener, server refresh, memory/settings availability messages.
