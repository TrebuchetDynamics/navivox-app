# Navivox Web QA — dl-mphmcspi-bb46a2

Date: 2026-05-22 18:55 CST
Scope: Flutter web build served locally from `build/web`
Target URL: `http://127.0.0.1:8765`

## Summary

- `flutter build web` passed and produced `build/web`.
- Local static serving on `127.0.0.1:8765` worked.
- Agent-browser loaded the setup route and captured screenshots/snapshots.
- The setup route is visually rendered, but the keyboard/screen-reader setup path is blocked by missing/incorrect semantics.

## Finding

### ISSUE-001 — Setup page controls are unlabeled and the visible Connect and talk button is not reachable through the web accessibility tree

Severity: High

A blind or keyboard-only web user cannot reliably complete setup. The visual page shows:

- `Gateway base URL`
- `Pairing token`
- `Connect and talk`

The accessible snapshot exposes only generic controls. After two Tabs, agent-browser observed:

```text
- button "Enable accessibility" [ref=e1]
- textbox [ref=e2]: http://127.0.0.1:8765
- button "Submit" [ref=e3]
- textbox [ref=e4]
- button "Submit" [ref=e5]
```

Additional evidence:

- `agent-browser find text "Connect and talk" click` returned `Element not found. Verify the selector is correct and the element exists in the DOM.`
- Filling the second textbox with `test-token` and pressing Enter left the URL at `http://127.0.0.1:8765/#/setup`.
- The network log after Enter contained only static asset requests; no gateway/API request was fired.
- Browser console output contained service-worker/debug messages and no JavaScript errors.

## Reproduction

1. From `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app`, run `flutter build web`.
2. Serve the build: `python3 -m http.server 8765 --bind 127.0.0.1 --directory build/web`.
3. Open `http://127.0.0.1:8765/#/setup`.
4. Capture an accessibility snapshot.
5. Press Tab twice.
6. Confirm the field labels and the visible `Connect and talk` action are not exposed.
7. Fill the second textbox with `test-token` and press Enter.
8. Confirm the route stays at `#/setup` and no gateway/API request fires.

## Suggested fix slice

Add explicit Flutter semantics and keyboard activation for the setup controls:

- Gateway base URL field label and hint.
- Pairing token field label and hint.
- QR import button label.
- Show/hide token button label.
- `Connect and talk` button semantic label and keyboard action.
- A focused widget regression test that asserts the semantics labels exist and keyboard/button activation triggers the connect action.

## Temporary QA artifacts

The run captured screenshots and video under `/tmp/navivox-web-qa-dl-mphmcspi-bb46a2-iter1/`. These are not committed and may be cleaned by the host.
