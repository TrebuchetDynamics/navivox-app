# Navivox App

Navivox is an Android-first Flutter app for talking to local or self-hosted Gormes agents.

It is the mobile operator console for a Gormes agent server: connect to a trusted gateway, chat with profile contacts, send text or device-transcribed voice turns, and watch assistant responses, tool activity, approvals, and recovery states stream back in a phone-friendly UI.

Navivox is intentionally not a generic server administration panel or a telephony suite. The first product loop is simple: connect to Gormes, prove the gateway is ready, and talk to an agent. The next product loop makes that agent understandable: inspect what it remembers, why it recalled something, and which memories need correction or cleanup.

## Relationship To Gormes

- **Gormes** is the Go-native agent runtime and gateway.
- **Navivox** is the Flutter app that presents the operator experience on Android and other Flutter targets.

Gormes owns agents, sessions, tools, provider calls, secrets, config, Goncho memory, and server-side policy. Navivox owns setup, chat, voice capture, streaming UI, tool cards, memory visualization, safe config presentation, and local recovery flows.

Gormes repository: <https://github.com/TrebuchetDynamics/gormes-agent>

## Status

Planning and early implementation.

Current focus:

1. Connect to a Gormes Navivox gateway with a base URL and optional token.
2. Verify `/healthz` and `/v1/navivox/status`.
3. Open the Navivox event stream.
4. Send the first text or device-transcribed voice turn.
5. Render assistant, system, tool, approval, and connection-state UI clearly.
6. Surface profile-scoped Goncho memory status so users can see whether memory is active, degraded, or unavailable.

## Screenshots

The screenshots below are generated from real Flutter widgets and checked by the test suite.

![Setup screen](docs/screenshots/setup.png)

![Chat screen](docs/screenshots/chat.png)

## Real-World Usage

Navivox is for moments when a user needs agent control away from a terminal:

- **Hands-free agent control:** ask a local Gormes profile to check status, summarize failures, restart safe services, or explain what changed.
- **Blind or low-vision operation:** use a screen-reader-friendly mobile surface for chat, voice turns, logs, memory, approvals, and recovery states.
- **Project briefings:** ask what happened overnight, which agents are blocked, what the latest successful test was, or what should happen next.
- **Incident response from a phone:** inspect gateway health, recent turns, active profile, provider state, and safe recovery actions.
- **Voice task capture:** turn spoken ideas, reminders, project notes, and corrections into durable agent context.
- **Agent fleet control:** switch between Gormes profiles, verify which one is active, and inspect each profile's health and memory.
- **Trust and privacy review:** see what the agent remembers, what influenced a response, and which memories should be corrected, archived, or marked stale.

## Goncho Memory Console

Navivox should make Gormes memory visible without turning the phone into a raw database browser. The app reads profile-scoped memory summaries through the Gormes Navivox API, not by opening SQLite directly.

The memory experience should help users answer:

- What does this profile remember?
- Is memory active, degraded, or unavailable?
- Which turns, summaries, entities, relationships, observations, and conclusions exist?
- Why might this memory be recalled now?
- What should be pinned, archived, corrected, or marked stale?

The local Mineru profile currently uses Goncho at `~/.gormes/profiles/mineru/memory.db`; that path is useful for operator diagnostics, but UI payloads should expose only safe labels and bounded summaries.

## Gateway Surface

Navivox expects a Gormes host exposing the Navivox channel:

- `GET /healthz` — basic readiness
- `GET /v1/navivox/status` — authenticated channel readiness
- `GET /v1/navivox/memory/overview` — authenticated Goncho memory health and safe count summary
- `GET /v1/navivox/sessions` — session listing
- `POST /v1/navivox/turn` — submit a user turn
- `WS /v1/navivox/stream` — stream session and assistant events

On the host side, `gormes navivox connect-info` prints reachable base URLs for setup.

## Repository Layout

```text
.
├── app/                         # Flutter app package
├── CONTEXT.md                   # Shared product language
├── navivox-architecture.md      # Architecture notes
├── navivox-chat-ui-research.md  # Chat UI research notes
├── navivox-data-model.md        # Data model notes
├── navivox-decision-record.md   # Product and technical decisions
├── navivox-library-research.md  # Flutter package research
├── navivox-prd.md               # Product requirements
├── navivox-routes.md            # App route plan
├── navivox-testing-plan.md      # Test strategy
└── navivox-ui-design.md         # UI design notes
```

## Development

Prerequisites:

- Flutter SDK
- A Gormes gateway with the Navivox channel enabled for full connect-and-talk testing

Run checks from the Flutter package:

```bash
cd app
flutter pub get
flutter test
```

Run the app:

```bash
cd app
flutter run
```

## Security And Product Boundaries

Navivox is built for trusted local or self-hosted Gormes deployments.

Important boundaries:

- The Navivox channel is disabled by default on the Gormes side.
- Local mode should stay loopback by default.
- Public exposure requires explicit server-side confirmation.
- Tokens must not be printed in screenshots, logs, route URLs, or deep links.
- The app should not directly edit local Gormes config files.
- The app should not open Gormes or Goncho SQLite databases directly; memory data must come through authenticated, profile-scoped Gormes APIs.
- Raw tool arguments, stdout, secrets, full logs, and secret-bearing memories should not be primary UI.
- Memory management should prefer pin/archive/mark-stale/correction flows over destructive deletion unless the server exposes an explicit safe deletion policy.

## Documentation

Start with:

- `CONTEXT.md`
- `navivox-prd.md`
- `navivox-architecture.md`
- `navivox-testing-plan.md`
- `navivox-ui-design.md`

## License

MIT License. See [LICENSE](LICENSE).
