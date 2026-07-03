# Connect Screen Simplification

**Date:** 2026-06-17
**Status:** historical approved Gormes connect-screen design; current fresh-install companion path is `/hermes`, with Gormes setup preserved as legacy runbooks.

## Problem

The setup/connect screen leads with a manual entry form (address field, port field, token field, three action buttons) even though most users arrive via a pairing link or QR image from `gormes navivox pair`. The form-first layout is inverted relative to the actual primary use case.

## Goal

Make "Import QR image" the primary action. Keep manual entry fully functional but hidden behind an expansion tile. Result: most users see one button; power users unfold the form.

## Layout structure

Three vertically-stacked sections:

1. **Hero** — logo + "Connect to Gormes" title + one instruction line:
   `Run gormes navivox pair, then scan the QR or open the pairing link.`
   Drop the `connect-info` fallback sentence from the hero (it moves to the help card).

2. **Action card** — top-level content:
   - `PairingReadinessCard` above the card when status is non-manual (unchanged)
   - Full-width `FilledButton.icon` → "Import QR image" (primary action, loading spinner during import)
   - `ExpansionTile` labeled "Enter manually" containing the manual form:
     - Single **Gateway URL** `TextField` (replaces separate address + port fields)
       - Default/placeholder: `http://127.0.0.1:8765`
       - Scheme detection on change (same logic as current `_handleAddressChanged`)
     - **Pairing token** `TextField` with `suffixIcon` `IconButton` for show/hide visibility
     - Full-width "Connect and talk" `FilledButton` (same semantics wrapper, inside expansion)
   - Notice banner (`_SetupNoticeBanner`) below the expansion when present
   - **Auto-expand rule:** when `_applyConnectionImport` populates the URL/token fields (QR or shared-text import that does not auto-connect), the expansion opens automatically so the user can review the filled fields and tap "Connect and talk". Implemented via an `ExpansionTileController` stored in state.

3. **Help card** — existing collapsible "Need setup help?" card, unchanged.

## Removed elements

- Separate address field + port field → replaced by single URL field
- Standalone "Show pairing token" / "Hide pairing token" `TextButton` → replaced by suffix icon inside token field
- "Copy fix instructions" `TextButton` → removed from main card (the help card copy-entry actions cover this)
- `networkHint` string from hero/main card → lives in help card only

## Files changed

### `lib/features/servers/screens/setup_screen.dart`

State:
- Replace `_addressController` + `_portController` with `_urlController` (init: `http://127.0.0.1:8765`)
- `_showToken` remains (drives suffix icon toggle)

Methods:
- Remove `_addressField()`, `_portField()` → add `_urlField()`
- `_handleAddressChanged` + `_handlePortChanged` → `_handleUrlChanged` (parses full URL, extracts scheme using existing `navivoxIsEndpointScheme`)
- `_submitManualPairingHandoff`: use `GatewayConnectionPresentation().splitBaseUrl(_urlController.text)` to extract address/port/scheme before building the connect request
- `dispose()`: swap controllers
- `_applyConnectionImport`: reconstruct full URL from `baseUrl` and set `_urlController.text` instead of splitting into two fields

Layout (`build`):
- Remove three-button `Wrap` → no standalone token toggle, no copy-fix button
- QR import button becomes top-level full-width `FilledButton` in the card
- Manual form wrapped in `ExpansionTile`
- Notice banner moves below the expansion tile (was below the button wrap)

### `lib/features/servers/setup/presentation/screen/setup_screen_presentation.dart`

- Replace `addressFieldLabel/SemanticLabel/SemanticHint` + `portFieldLabel/SemanticLabel/SemanticHint` with `urlFieldLabel`, `urlFieldSemanticLabel`, `urlFieldSemanticHint`
- Shorten `pairingInstructions` to one sentence
- Add `enterManuallyLabel` → `'Enter manually'`
- Remove `fixInstructionsButtonLabel` (unused after card removal)
- `tokenVisibilityLabel` remains (drives suffix icon tooltip/label)

## Data flow

URL parsing uses the already-present `GatewayConnectionPresentation.splitBaseUrl`. No new parsing logic. The result shape (`address`, `port`, `baseUrl`, `hasError`) is unchanged — only the call site moves from submit-time construction to `_handleUrlChanged` + submit.

## What does not change

- `PairingReadinessCard` and its five status variants
- `_SetupNoticeBanner`
- `_SetupHero` widget
- `_SetupHelpCard` widget
- All pairing intent / coordinator / handoff flow logic
- Auto-reconnect logic
- Connect intent source / deep link handling
- Regression tests (presentation layer is backward-compatible; new url field semantic labels need one test update)
