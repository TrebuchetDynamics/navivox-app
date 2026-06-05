# Navivox App

**Private voice/chat for your own Gormes agents.**

Navivox remains an Android-first Flutter app for talking to trusted local or self-hosted Gormes profiles. It gives each profile a Telegram-style contact surface while keeping the agent control plane in Gormes instead of a third-party chat platform.

Navivox can learn product and UI patterns from `fathah/hermes-desktop`: chat first, profile/session/model/provider/memory/tool/gateway surfaces close at hand, and streaming assistant work rendered as product UI instead of terminal output. Hermes Desktop is a reference app, not the near-term Navivox runtime target.

Navivox is intentionally not a generic server administration panel or a telephony suite. The first product loop is simple: connect to Gormes, prove the gateway is ready, talk to an agent, and inspect its memory and operator evidence.

## Relationship To Gormes And Reference Apps

- **Gormes** is the Go-native agent runtime and gateway.
- **Navivox** is the Flutter app that presents the Gormes operator experience on Android and other Flutter targets.
- **Hermes Desktop** is a product reference for app shape and UI ideas; it is not a wire-protocol target for the main Navivox plan.

Gormes owns agents, sessions, tools, provider calls, secrets, config, Goncho memory, and server-side policy. Navivox owns setup, chat, voice capture, streaming UI, tool cards, memory visualization, safe config presentation, and local recovery flows.

References:

- Gormes repository: <https://github.com/TrebuchetDynamics/gormes-agent>
- Hermes Desktop reference: <https://github.com/fathah/hermes-desktop>

## Status

Early implementation. The core connect-and-talk loop has Flutter screens, protocol models, widget/unit tests, generated README screenshots, and an active Gormes `gormes navivox pair` handoff. Treat mobile release polish, app-store packaging, and full voice/TTS loops as in progress.

Current focus:

1. Connect to a trusted Gormes Navivox gateway.
2. Send text or device-transcribed voice turns.
3. Render assistant, tool, approval, connection, run-record, and memory-state UI clearly.
4. Borrow proven app-shape ideas from Hermes Desktop without changing the Gormes runtime boundary.

## Screenshots

The screenshots below are generated from real Flutter widgets and checked by the test suite.

![Setup screen](docs/screenshots/setup.png)

![Chat screen](docs/screenshots/chat.png)

## Real-World Usage

Navivox is for mobile agent operation: hands-free chat, project briefings, incident checks, voice task capture, agent switching, and screen-reader-friendly control away from a terminal.

## Why It Is Cool

- **Agents become contacts.** Each Gormes profile can feel like a trusted chat contact instead of a terminal session.
- **Voice first, not telephony first.** Device-transcribed voice can become a normal Gormes turn without phone numbers, campaigns, or call-center setup.
- **Tool work is visible.** Assistant text, tool cards, approvals, safety notices, and recovery states are UI objects rather than pasted logs.
- **The control plane stays yours.** Gormes owns sessions, memory, tools, secrets, provider execution, and retention policy; Navivox presents the operator surface.

## Privacy And Control

Navivox is designed to be more private than Telegram bot chat for agent operation because the normal path does not route your agent conversations through Telegram's cloud or bot API. A trusted Gormes gateway owns auth, routing, provider calls, tool policy, memory, and retention; Navivox sends typed HTTP/WebSocket actions over a local, VPN, or tailnet connection.

Privacy still depends on deployment choices:

- Local or self-hosted Gormes plus device/local STT keeps the strongest boundary.
- Cloud model, STT, or TTS providers may still process submitted text, transcripts, or audio according to their own policies.
- Public exposure is discouraged and requires explicit server-side confirmation.
- Pairing tokens, deep links, terminal QRs, and QR PNGs are secret material; never paste them into issues, logs, screenshots, or chat transcripts.

## Goncho Memory Console

Navivox makes Gormes memory inspectable without becoming a raw database browser. It should show memory health, counts, search results, provenance, and safe management actions such as pin, archive, correction, or mark stale.

The app reads memory through authenticated, profile-scoped Gormes APIs. It must not open SQLite directly.

## Gateway Surface

Navivox expects a Gormes host exposing the Navivox channel:

- `GET /healthz` — basic readiness
- `GET /v1/navivox/status` — authenticated channel readiness
- `GET /v1/navivox/capabilities` — versioned feature and endpoint contract for capability-gated UI
- `GET /v1/navivox/profile-contacts` — profile contact snapshot for the chat list
- `GET /v1/navivox/profile-routing` — server/profile routing snapshot
- `POST /v1/navivox/profile-seed` — draft or apply a profile from operator text
- `GET /v1/navivox/config-admin[/schema]` — safe config admin read/schema
- `POST /v1/navivox/config-admin/{diff,validate,apply}` — safe config admin mutations
- `GET /v1/navivox/voice-profiles` — per-profile STT/TTS voice profile state
- `POST /v1/navivox/voice-profiles/validate` — voice profile validation
- `GET /v1/navivox/run-records/{run_id_or_session_id}` — run-record lookup
- `GET /v1/navivox/memory/overview` — authenticated Goncho memory health and safe count summary
- `GET /v1/navivox/sessions` — session listing
- `GET /v1/navivox/sessions/{session_id}` — session detail
- `POST /v1/navivox/turn` — submit a user turn
- `WS /v1/navivox/stream` — stream session and assistant events

Navivox should enable profile creation/import, attachment, voice, and stream affordances from `/v1/navivox/capabilities` instead of assuming unsupported routes exist.

On the host side, `gormes navivox pair` is the recommended setup path. It starts a network-reachable bridge, generates or reuses a pairing token, writes a QR image, prints a compact terminal QR when the screen is wide enough, opens Navivox directly on Android when requested, and waits for Navivox connection. `gormes navivox connect-info` remains the fallback for older Gormes builds or manual setup.

## Repository Layout

```text
.
├── lib/                         # Flutter app source
├── test/                        # Widget, unit, and tooling tests
├── integration_test/            # Connect-and-talk integration tests
├── web/                         # Flutter web shell
├── linux/                       # Flutter Linux runner
├── docs/                        # Product, architecture, research, ADRs, runbooks, screenshots
│   ├── architecture/            # Architecture, data model, decision notes
│   ├── product/                 # PRD, route plan, UI design, test strategy
│   ├── research/                # Research notes and analyst summaries
│   ├── adr/                     # Architecture decision records
│   ├── runbooks/                # Android, Termux, release, and QA handoffs
│   └── screenshots/             # README screenshots generated from widgets
├── playwright/                  # Web QA tests, probes, debug scripts, and screenshots
└── CONTEXT.md                   # Shared product language
```

## Install And Run

Prerequisites:

- Flutter SDK on `PATH`
- Android SDK or another Flutter target for local app runs
- A trusted Gormes gateway with the Navivox channel enabled for full connect-and-talk testing

Install dependencies from the repository root:

```bash
flutter pub get
```

Run the local verification gate:

```bash
flutter analyze
flutter test
```

Find available Flutter targets:

```bash
flutter devices
```

Run the app from the repository root, replacing `<device-id>` with one of the listed targets:

```bash
flutter run -d <device-id>
```

Android target notes:

- Android emulator: use `http://10.0.2.2:<port>` when the Gormes gateway is running on the host machine.
- A physical Android device cannot reach the host through `127.0.0.1`; use the host LAN, VPN, or Tailscale URL printed by `gormes navivox pair` or the `gormes navivox connect-info` fallback.
- Same Android device with Gormes in Termux: Install Termux, paste one command, then continue in Navivox. Follow `docs/runbooks/termux/gormes-bootstrap.md`.
- Recommended setup path: `gormes navivox pair`.
- Keep the pairing token inside Navivox only; never paste it into issue reports, logs, screenshots, or chat transcripts.

## Connected Smoke Test

Use this only with a trusted local or self-hosted Gormes host:

1. Start or select a Gormes host with the Navivox channel enabled.
2. On the host or in Termux, start the app-first pairing handoff:

   ```bash
   gormes navivox pair
   ```

   This should start local bridge, generate a pairing token, show a QR, print localhost URL, and wait for Navivox connection. `gormes navivox connect-info` remains the fallback when pairing is unavailable or manual setup is required.

3. Confirm the gateway answers `GET /healthz` and authenticated `GET /v1/navivox/status`.
4. Scan/import the QR, or copy the reachable base URL into the Navivox setup screen.
5. If setup output prints a token, paste it into Navivox only. Do not paste tokens into issues, logs, or screenshots.
6. Send a short text turn and confirm the app shows an assistant response, tool activity, or a clear connection recovery state.

## Troubleshooting

- If Flutter is missing, run `flutter doctor` and fix the reported SDK or platform setup before running Navivox.
- If `flutter devices` shows `No supported devices found`, start an emulator, connect an Android device, or choose another Flutter target that appears in the device list.
- If `flutter run -d <device-id>` fails after a layout move, run `flutter clean` and `flutter pub get` from the repository root. Do not delete source files while clearing generated state.
- If the setup screen shows `Connection refused`, confirm the Gormes host is running, reachable from the device, and listening on the base URL from `gormes navivox pair` or the `gormes navivox connect-info` fallback.
- If the gateway returns `401` or `403`, refresh setup with `gormes navivox pair` or `gormes navivox connect-info`, then paste the token into Navivox only.

## Security And Product Boundaries

Navivox is built for trusted local or self-hosted Gormes deployments.

Important boundaries:

- Navivox is for trusted local or self-hosted Gormes deployments.
- Public exposure requires explicit server-side confirmation.
- Tokens, secrets, raw tool output, and full logs must not be primary UI.
- Config and Goncho memory are managed through authenticated Gormes APIs, not direct file or SQLite edits.
- Memory management should prefer pin/archive/mark-stale/correction flows over destructive deletion.

## Documentation

Start with:

- `CONTEXT.md`
- `docs/product/hermes-desktop-reference.md`
- `docs/README.md`
- `docs/runbooks/termux/gormes-bootstrap.md`
- [Gormes Navivox CLI docs](https://docs.gormes.ai/cli/navivox/)
- `docs/product/prd.md`
- `docs/architecture/architecture.md`
- `docs/product/testing-plan.md`
- `docs/product/ui-design.md`

## License

MIT License. See [LICENSE](LICENSE).
