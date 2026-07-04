# Hermes Desktop architecture and feature research for Navivox

Status: active reference research
Research date: 2026-07-04
Reference: local `hermes-desktop/` checkout inspected during the goal session, `fathah/hermes-desktop` commit `4ce086c` (`Update package.json`)
Purpose: capture Hermes Desktop architecture, technology, features, and concrete lessons for finishing/improving Navivox as a Hermes Agent mobile companion.

## Executive summary

Hermes Desktop is an Electron/React desktop shell for Hermes Agent. Its core shape is: Electron main process for privileged local/remote/SSH Hermes lifecycle, filesystem/config/database access, gateway/dashboard transports, updater/install flows, and IPC; a sandboxed React renderer for chat and operator surfaces; and shared TypeScript stream/session/tool data modules. Its README describes the product as a GUI for installing, configuring, and chatting with Hermes Agent, including sessions, profiles, memory, skills, tools, schedules, messaging gateways, and more (`hermes-desktop/README.md:44-46`).

For Navivox, the most useful patterns are:

1. Use Hermes-native product language: endpoint, session/conversation, model, provider, skill, toolset, job, gateway.
2. Keep chat/session as the primary workspace, not a side feature.
3. Gate run transport on `/v1/capabilities` and fall back when run events are unavailable or unsafe.
4. Keep SSE/run parsing as a pure, fixture-tested seam.
5. Reconcile streamed transcript with persisted session history after completion.
6. Stage Desktop parity as read-only or hidden mobile surfaces before mutation.
7. Preserve strict security/redaction boundaries for secrets, logs, tool payloads, transcript content, and local paths.

## Evidence base

Inspected during the research pass:

- `hermes-desktop/README.md`, `Development.md`, `scripts/README.md`, `lat.md/*.md`.
- `hermes-desktop/package.json`, `electron.vite.config.ts`, `electron-builder.yml`, `.github/workflows/ci.yml`, `.github/workflows/release.yml`.
- `hermes-desktop/src/main/app/start.ts`, `src/main/ipc/register.ts`, `src/main/hermes.ts`, `src/main/run-stream.ts`, `src/main/sse-parser.ts`, `src/main/config.ts`, `src/main/secrets/*`, `src/main/profiles.ts`, `src/main/db.ts`.
- `hermes-desktop/src/preload/index.ts`.
- `hermes-desktop/src/renderer/src/App.tsx`, `src/renderer/src/screens/Layout/Layout.tsx`, `src/renderer/src/screens/Chat/*`.
- Current Navivox docs: `docs/product/hermes-agent-interface-plan.md`, `docs/product/hermes-desktop-parity-roadmap.md`, `docs/adr/0007-native-hermes-channel-not-navivox-channel-adapter.md`.

Repository scan counts from the inspected checkout:

- `src`: 653 files.
- `src/main`: 90 files.
- `src/renderer/src`: 284 files.
- `src/preload`: 3 files.
- top-level `tests`: 98 files.
- renderer colocated tests: 29 files.
- main colocated tests: 16 files.

## Technology stack

| Layer | Hermes Desktop technology | Evidence | Navivox lesson |
| --- | --- | --- | --- |
| App shell | Electron 39, electron-vite 5, electron-builder 26 | `package.json` declares Electron/electron-vite/electron-builder (`hermes-desktop/package.json:77-79`) and `main: ./out/main/index.js` (`hermes-desktop/package.json:5`) | Do not copy Electron, but copy the process-boundary model: UI calls constrained services. |
| UI | React 19, React DOM 19, Tailwind 4 Vite plugin, Radix dialog, lucide icons, motion | Dependencies in `package.json` (`hermes-desktop/package.json:36-60`, `hermes-desktop/package.json:88-90`) | Flutter UI should be componentized around chat/session/control surfaces, not one giant screen. |
| 3D/Office | Three, React Three Fiber, Drei, troika-three-text | Dependencies (`hermes-desktop/package.json:37-38`, `hermes-desktop/package.json:57-58`) and Vite Three dedupe note (`hermes-desktop/electron.vite.config.ts:25-33`) | Desktop-only; defer for mobile except optional status/link. |
| Data | better-sqlite3 for Hermes `state.db`; JSON/YAML/dotenv files in `~/.hermes` | `better-sqlite3` dependency (`hermes-desktop/package.json:42`), cached DB opener (`hermes-desktop/src/main/db.ts:1-31`) | Navivox should use Hermes APIs, not local DB/file guessing. |
| Streaming | HTTP/HTTPS SSE, WebSocket dashboard client, CLI fallback | `src/main/hermes.ts` imports HTTP/HTTPS/WebSocket; dashboard hooks expose prompt/background command flows (`hermes-desktop/src/renderer/src/screens/Chat/hooks/useDashboardChatTransport.ts:112-125`) | Keep Dart SSE parsing pure/tested; avoid Desktop-only fallback complexity. |
| Secrets | `.env` provider plus opt-in command provider | README secret order (`hermes-desktop/README.md:252-260`); `getSecret` order and spawn floor (`hermes-desktop/src/main/secrets/index.ts:47-91`) | Keep Navivox API keys in secure storage only; never leak through logs/diagnostics/routes. |
| Tests | Vitest, React Testing Library, jsdom, fast-check, Playwright scripts | Scripts/dev deps (`hermes-desktop/package.json:10-18`, `hermes-desktop/package.json:67-93`) | Continue parser/channel/widget tests plus deterministic fake and env-gated live smokes. |
| Release | electron-builder and GitHub Actions | Builder config (`hermes-desktop/electron-builder.yml:15-73`), release workflow multi-platform jobs (`hermes-desktop/.github/workflows/release.yml:63-180`) | Mobile release readiness is separate; do not import Desktop packaging assumptions. |

## High-level architecture

### Electron main process

`src/main/index.ts` is a thin entry: apply GPU preferences/crash guard, optionally enable a dev CDP port, then call `startMainProcess()`. `startMainProcess()` registers IPC, updater, lifecycle cleanup, CSP, window security, menus, and creates the main window (`hermes-desktop/src/main/app/start.ts:36-55`, `hermes-desktop/src/main/app/start.ts:77-97`).

Main-process responsibilities:

- BrowserWindow creation and Electron hardening (`hermes-desktop/src/main/app/start.ts:142-162`).
- CSP and remote/local connection allowances (`hermes-desktop/src/main/app/start.ts:77-94`).
- External URL validation before open (`hermes-desktop/src/main/app/start.ts:129-136`, `hermes-desktop/src/main/app/start.ts:191-198`).
- Webview hardening for the web-preview partition (`hermes-desktop/src/main/app/start.ts:62-72`, `hermes-desktop/src/main/app/start.ts:200-207`).
- Cleanup of health polling, active runs, temp media, dashboards, and DB on quit (`hermes-desktop/src/main/app/start.ts:108-115`).
- Privileged Hermes operations through IPC: install, config, remote/SSH, chat, sessions, models, memory, soul/persona, tools, skills, cron, messaging, Kanban, wallets, logs, updater (`hermes-desktop/src/main/ipc/register.ts:47-66`, `hermes-desktop/src/main/ipc/register.ts:87-129`, `hermes-desktop/src/main/ipc/register.ts:200-301`).

Navivox implication: keep UI widgets away from auth headers, URL assembly, redaction, local storage, shell/process decisions, and stream parsing. The existing `HermesApiClient` + `HermesChannel` split is the right shape.

### Preload bridge

The preload exposes a tiny `electron` version/platform surface and a large `hermesAPI` IPC allowlist (`hermes-desktop/src/preload/index.ts:67-79`). `hermesAPI` includes install, configuration, connection mode, SSH, chat, audio transcription, media, models, registry/MCP, and logs (`hermes-desktop/src/preload/index.ts:78-140`, `hermes-desktop/src/preload/index.ts:241-400`, `hermes-desktop/src/preload/index.ts:1440-1445`). It is published with `contextBridge.exposeInMainWorld` when context isolation is enabled (`hermes-desktop/src/preload/index.ts:1448-1452`).

Navivox implication: do not grow one global mega-service. Keep a narrow Hermes companion contract: connect, sessions, send/stop/approval, voice transcript submission, catalogs/readiness, bounded diagnostics.

### Renderer startup

Renderer startup is a finite screen state machine: `splash`, `welcome`, `installing`, `setup`, `main` (`hermes-desktop/src/renderer/src/App.tsx:15-26`). Splash checks connection mode, remote reachability, local install/API key, then warms config-health/gateway status (`hermes-desktop/src/renderer/src/App.tsx:44-96`). It deliberately skips local deep verification in remote mode because local Python/script probes do not apply there (`hermes-desktop/src/renderer/src/App.tsx:112-126`).

Navivox implication: endpoint setup must be mode-aware. Android emulator, physical-device LAN/VPN/Tailscale, and trusted remote HTTPS should be explained separately. A failed remote probe should not route to legacy Gormes setup.

### Layout and navigation

Desktop's main `View` union includes chat, discover, agents/profiles, office, providers, skills, memory, tools, schedules, Kanban, and gateway (`hermes-desktop/src/renderer/src/screens/Layout/Layout.tsx:53-64`). Pinned nav emphasizes Discover, Office, Kanban, Schedules; footer nav includes Providers, Gateway, Tools, Memory (`hermes-desktop/src/renderer/src/screens/Layout/Layout.tsx:66-82`). Sessions are integrated into the chat workspace through sidebar recent sessions and a full Sessions modal rather than a primary nav item (`hermes-desktop/src/renderer/src/screens/Layout/Layout.tsx:657-673`, `hermes-desktop/src/renderer/src/screens/Layout/Layout.tsx:809-829`).

Remote mode hides local-only surfaces behind `RemoteNotice` for Discover, Agents, Providers, Skills, Memory, Kanban, and Gateway (`hermes-desktop/src/renderer/src/screens/Layout/Layout.tsx:834-858`, `hermes-desktop/src/renderer/src/screens/Layout/Layout.tsx:868-897`, `hermes-desktop/src/renderer/src/screens/Layout/Layout.tsx:920-936`).

Navivox implication: mobile should not reproduce the large Desktop nav. Use a smaller companion topology:

- primary: chat/session and voice;
- secondary read-only: health/readiness, models/providers, skills/toolsets, jobs;
- hidden/deferred: config admin, memory mutation, persona edit, messaging gateway setup, raw logs, Office.

### Chat architecture

`Chat` composes focused pieces: input, empty state, message list, model picker, reasoning picker, context folder, worktree/remote folder, web preview, scroll hook, IPC hook, action hook, model config hook, fast mode, local commands, dashboard transport, transcript builder, config-health banner, queued messages, and slash catalogs (`hermes-desktop/src/renderer/src/screens/Chat/Chat.tsx:1-49`). One `Chat` is mounted per run; multiple conversations remain mounted while only the active one is visible (`hermes-desktop/src/renderer/src/screens/Chat/Chat.tsx:88-111`, `hermes-desktop/src/renderer/src/screens/Layout/Layout.tsx:777-805`).

Important patterns:

- Per-run event isolation: IPC events carry `runId` and listeners drop events for other runs (`hermes-desktop/src/renderer/src/screens/Chat/hooks/useChatIPC.ts:28-45`).
- Mid-stream DB refresh and final reconciliation preserve tool/reasoning/session history accuracy (`hermes-desktop/src/renderer/src/screens/Chat/hooks/useChatIPC.ts:78-118`, `hermes-desktop/src/renderer/src/screens/Chat/hooks/useChatIPC.ts:179-221`).
- Dashboard transport can run slash commands and background prompts without blocking the main turn (`hermes-desktop/src/renderer/src/screens/Chat/hooks/useDashboardChatTransport.ts:112-125`; `hermes-desktop/src/renderer/src/screens/Chat/hooks/useChatActions.ts:20-31`, `hermes-desktop/src/renderer/src/screens/Chat/hooks/useChatActions.ts:204-225`).
- Busy main turns queue normal follow-ups; side questions bypass the queue (`hermes-desktop/src/renderer/src/screens/Chat/Chat.tsx:707-790`).

Navivox implication: the `/hermes` screen should keep moving toward a session-first workspace: active session sheet, in-flight isolation, stop/approval state, queued follow-up affordance, and final transcript reconciliation.

## Transport architecture

### Connection modes

Desktop supports local, remote HTTP, and SSH modes (`hermes-desktop/src/main/config.ts:45-52`). The public connection config exposes mode, remote URL, transport preferences, API key presence/length, and SSH fields while withholding the actual API key (`hermes-desktop/src/main/config.ts:54-64`). `getApiUrl()` resolves SSH tunnel URL, remote URL, or a per-profile local gateway port (`hermes-desktop/src/main/hermes.ts:122-137`). Auth headers use remote bearer for remote/SSH and local `API_SERVER_KEY` only in local mode (`hermes-desktop/src/main/hermes.ts:169-182`).

Navivox implication: one endpoint is the correct MVP. Later multi-endpoint work must isolate endpoint identity, secure key alias, session cache, diagnostics, forget/revoke behavior, and profile labels.

### Capability-gated runs

`supportsHermesRunsTransport()` requires feature flags and exact endpoint paths for run submission, SSE events, stop, approval response, and tool progress (`hermes-desktop/src/main/run-stream.ts:25-39`). `sendMessageViaNonGatewayApi()` consults capabilities and uses `/v1/runs` only for non-attachment, non-approval turns; otherwise it falls back to chat completions (`hermes-desktop/src/main/hermes.ts:2637-2664`).

Run transport posts `/v1/runs`, opens `/v1/runs/{run_id}/events`, parses SSE, maps `message.delta`, `reasoning.available`, tool started/completed/failed, usage, completion/failure/cancel, and posts stop on abort (`hermes-desktop/src/main/hermes.ts:1607-1884`). If start/events fail before useful output, it falls back (`hermes-desktop/src/main/hermes.ts:1668-1688`, `hermes-desktop/src/main/hermes.ts:1771-1827`, `hermes-desktop/src/main/hermes.ts:1847-1859`).

Navivox implication: keep strict capability checks. Do not render run-only controls unless the capability advertises them and tests cover the event shape.

### SSE parsing seams

Desktop has extracted SSE parsing logic (`hermes-desktop/src/main/sse-parser.ts:1-27`) and run-stream helpers (`hermes-desktop/src/main/run-stream.ts:50-118`). Custom events parse tool progress; data chunks parse usage, content, and errors; malformed chunks are skipped rather than crashing.

Navivox implication: continue pure Dart `HermesSseEventDecoder` tests for multi-line data, CRLF, named events, malformed events, tool progress, reasoning, usage, done, and stream drop/reconnect cases.

### Session IDs and transcript integrity

Desktop generates `desk-<timestamp>-<uuid>` and sends `X-Hermes-Session-Id` to avoid server fingerprint collisions (`hermes-desktop/src/main/hermes.ts:1257-1287`). It announces/reconciles session IDs and reloads persisted messages after stream completion.

Navivox implication: keep `navi-*` client IDs, server ID reconciliation, and `GET /api/sessions/{id}/messages` final reconciliation. This is more important than Desktop parity cosmetics.

### CLI/TUI fallback

Local Desktop can fall back to TUI gateway and CLI (`hermes-desktop/src/main/hermes.ts:2288-2346`, `hermes-desktop/src/main/hermes.ts:2864-2940`). Remote mode does not use CLI fallback.

Navivox implication: do not add CLI fallback to mobile. Mobile should target a reachable Hermes API endpoint. Termux/local Hermes is a separate runtime and should wait for explicit receipts.

## Data and persistence model

| Data | Desktop storage/access | Evidence | Navivox treatment |
| --- | --- | --- | --- |
| Connection config | `~/.hermes/desktop.json`; public config hides API key value | `desktopConfigFile()` and public shape (`hermes-desktop/src/main/config.ts:67-94`, `hermes-desktop/src/main/config.ts:54-64`) | Save base URL non-secret; API key only in secure storage. |
| Provider/API keys | `.env` default; optional command provider; process env wins | README (`hermes-desktop/README.md:252-260`); `getSecret` (`hermes-desktop/src/main/secrets/index.ts:47-63`) | Never leak key into shared prefs, route state, logs, screenshots, or diagnostics. |
| Profiles | default `HERMES_HOME` plus named dirs under `~/.hermes/profiles` | `PROFILES_DIR` and list logic (`hermes-desktop/src/main/profiles.ts:22-50`, `hermes-desktop/src/main/profiles.ts:129-218`) | Defer multi-profile; map later to endpoints/profile contexts, not Gormes contacts. |
| Sessions/history | Hermes `state.db` via better-sqlite3 in main process | DB cached connection (`hermes-desktop/src/main/db.ts:1-31`) | Use `/api/sessions` and `/messages`, not DB. |
| Config/model/provider | `config.yaml`, `.env`, Desktop config helpers | IPC imports model/config helpers (`hermes-desktop/src/main/ipc/register.ts:183-211`) | Read-only until Hermes exposes safe config APIs or explicit CLI contract. |
| Logs/debug/backup | Settings + installer/log helpers | README features (`hermes-desktop/README.md:153-154`), preload log API (`hermes-desktop/src/preload/index.ts:1440-1445`) | Bounded diagnostics only; raw logs/export later with redaction contract. |

## Feature inventory and Navivox applicability

| Desktop feature | Evidence | Copy now? | Navivox note |
| --- | --- | --- | --- |
| Guided local install | README (`hermes-desktop/README.md:138`, `hermes-desktop/README.md:161-168`) | No | Mobile connects to existing endpoint; Termux install remains a runbook. |
| Local/remote backend | README (`hermes-desktop/README.md:139`, `hermes-desktop/README.md:170`) | Yes | Existing setup presets are good; keep improving endpoint health. |
| SSH mode | preload connection API (`hermes-desktop/src/preload/index.ts:241-367`) | Later | Needs mobile-native tunnel story. |
| Streaming chat | README (`hermes-desktop/README.md:141-142`) | Yes | Main product value. |
| Slash commands | README (`hermes-desktop/README.md:143`), command list (`hermes-desktop/src/renderer/src/screens/Chat/slashCommands.ts:10-174`) | Partial | Add only mobile-safe subset/palette. |
| Sessions/history/search | README (`hermes-desktop/README.md:144`, `hermes-desktop/README.md:176-178`) | Yes | Add search/date grouping after reliability receipts. |
| Profiles | README (`hermes-desktop/README.md:145`) | Later | Endpoint/profile contexts, not Gormes Profile contacts. |
| Models/providers | README (`hermes-desktop/README.md:140`, `hermes-desktop/README.md:149`, `hermes-desktop/README.md:197-213`) | Read-only now | Current catalog strip can grow detail/health. |
| Toolsets/skills | README (`hermes-desktop/README.md:146`, `hermes-desktop/README.md:179`, `hermes-desktop/README.md:183`) | Read-only now | Inventory first; enable/disable later. |
| Memory | README (`hermes-desktop/README.md:147`, `hermes-desktop/README.md:181`) | Later | Needs explicit Hermes memory API and redaction. |
| Persona/SOUL | README (`hermes-desktop/README.md:148`, `hermes-desktop/README.md:182`) | Later | Do not edit remote files by guessing paths. |
| Schedules/jobs | README (`hermes-desktop/README.md:150`, `hermes-desktop/README.md:184`) | Read-only next | Expand jobs inventory; mutation later. |
| Messaging gateways | README (`hermes-desktop/README.md:151`, `hermes-desktop/README.md:215-217`) | Later/status only | Setup/admin is broad and secret-heavy. |
| Office/Claw3d | README (`hermes-desktop/README.md:152`, `hermes-desktop/README.md:186`) | Out | Desktop-only. |
| Backup/import/raw logs | README (`hermes-desktop/README.md:153-154`, `hermes-desktop/README.md:187`) | Bounded diagnostics only | Raw export needs redaction and explicit user action. |
| Auto-updater | README (`hermes-desktop/README.md:155`) | No | Mobile uses app/build release flow. |
| i18n/theme/accessibility | README (`hermes-desktop/README.md:156`) | Yes | Keep all new surfaces accessible and understandable. |
| CDP live regression scripts | scripts docs (`hermes-desktop/scripts/README.md:1-9`, `hermes-desktop/scripts/README.md:32-53`) | Concept yes | Keep Navivox fake/live/provider/browser smokes separated. |

## Security and privacy findings to preserve

1. Renderer sandbox/context isolation and preload allowlist are central (`hermes-desktop/src/main/app/start.ts:154-162`, `hermes-desktop/src/preload/index.ts:1448-1452`).
2. CSP and webview allowlists are explicit (`hermes-desktop/src/main/app/start.ts:77-94`, `hermes-desktop/src/main/app/start.ts:62-72`, `hermes-desktop/src/main/app/start.ts:200-207`).
3. External URLs are validated before opening (`hermes-desktop/src/main/app/start.ts:129-136`).
4. Command secret provider passes key names as env data, caps timeout/output, pipes stderr, and avoids logging secret values (`hermes-desktop/src/main/secrets/commandProvider.ts:123-172`, `hermes-desktop/src/main/secrets/commandProvider.ts:183-207`).
5. Remote mode hides local mutation screens (`hermes-desktop/src/renderer/src/screens/Layout/Layout.tsx:834-858`, `hermes-desktop/src/renderer/src/screens/Layout/Layout.tsx:868-897`, `hermes-desktop/src/renderer/src/screens/Layout/Layout.tsx:920-936`).

Navivox policy: no secrets, bearer headers, raw logs, transcript bodies, tool payloads, private local paths, or screenshots with sensitive text in readiness exports.

## Testing and delivery model

Desktop CI runs install, typecheck, tests, and non-gating lint (`hermes-desktop/.github/workflows/ci.yml:1-44`). Release jobs build platform artifacts through electron-builder (`hermes-desktop/.github/workflows/release.yml:63-180`, `hermes-desktop/electron-builder.yml:15-73`). Dev CDP scripts attach to a running app and can call `window.hermesAPI` directly (`hermes-desktop/scripts/README.md:27-31`, `hermes-desktop/scripts/README.md:131-134`).

Navivox should keep three validation tiers:

- deterministic unit/widget/parser tests;
- browser fake Hermes smoke;
- env-gated installed/provider/Android/native-host receipts that block readiness but do not replace deterministic tests.

## What Navivox already copied successfully

- Native `HermesChannel`, not a `NavivoxChannel` adapter (`docs/adr/0007-native-hermes-channel-not-navivox-channel-adapter.md`).
- `lib/core/hermes/` client/channel/models/SSE/policy package.
- `/hermes` route and Hermes chat/session screen.
- Capability-gated run transport, stop, approvals, tool cards.
- Session rename/delete/fork.
- Local device STT transcript submitted as Hermes text.
- Read-only catalog strip and health detail.
- Setup presets for local/emulator/remote.
- Readiness guardrails and strict audit language.

## Recommended Navivox improvement plan

### Priority 0 — keep readiness honest

Do not claim broad completion until the external receipts are real: Android spoken microphone, native host Windows/iOS/macOS, provider-backed chat/voice, and durable reconnect where still relevant. Desktop research does not replace these gates.

### Priority 1 — session-first chat UX polish

Borrow Desktop's strongest mobile-relevant pattern: sessions live inside chat.

Tasks:

- Add a mobile session sheet with search/date grouping/resume/create.
- Preserve active session/run identity through streaming, stop, approval, and reconciliation.
- Add queued follow-up UX for busy sessions.
- Keep error/offline/auth-expired states bounded and recoverable.

Acceptance evidence:

- widget tests for empty/loading/error/search states;
- SSE/drop/reconcile tests;
- fake browser smoke covering search/resume and queued follow-up.

### Priority 2 — bounded chat power features

Copy selectively:

- small command palette/slash subset for `help`, `usage`, `tools`, `skills`, `model`, `status` where supported;
- context/token usage display when Hermes stream usage is present;
- read-only detail dialogs for models/providers/skills/toolsets/jobs;
- attachments only after fixtures prove image/text/path semantics on web and Android.

Do not copy CLI fallback, web preview, worktree panels, or raw path-ref attachment semantics yet.

### Priority 3 — read-only operator surfaces

Add mobile-value cards before admin:

- models/providers health and selected model;
- skills/toolsets inventory;
- jobs/schedules inventory;
- endpoint health/capability version detail;
- bounded diagnostics export.

Mutation gates: explicit Hermes API capability, auth recovery, destructive confirmation, redaction tests, hidden fallback when absent.

### Priority 4 — endpoint/profile management

After chat and receipts stabilize:

- multiple Hermes endpoints with secure key aliases;
- endpoint/session cache isolation;
- optional Hermes profile selection only with explicit API/CLI contract;
- forget/revoke behavior.

Avoid "Profile contacts" terminology; it belongs to Gormes legacy.

## Risks if Navivox copies Desktop too literally

- Surface overload: Desktop has many screens; mobile should remain a companion.
- Local file coupling: Desktop can inspect `~/.hermes`; mobile remote mode must use APIs.
- Secret exposure: provider/gateway/admin/log surfaces can leak keys and paths.
- Transport confusion: Desktop has TUI gateway, `/v1/runs`, `/v1/chat/completions`, dashboard WebSocket, and CLI fallback; mobile should expose one stable path plus gated controls.
- Desktop release assumptions: updater, code signing, Linux sandbox fixes, and Office/Claw3d do not translate to Android/iOS readiness.

## Prompt-to-artifact checklist

Objective: "do extensive research of architecture, technology, features etc of `@hermes-desktop/` so we can finish and improve Navivox."

| Requirement | Artifact evidence |
| --- | --- |
| Research architecture | High-level architecture, main/preload/renderer/chat/transport/data sections. |
| Research technology | Stack table from package/build/test/release configs. |
| Research features | Feature inventory table sourced from Desktop docs/code. |
| Connect findings to Navivox | Navivox implications and prioritized improvement plan. |
| Avoid unsafe parity copying | Risks, redaction rules, read-only/mutation gates. |
| Source evidence | Claims cite inspected Hermes Desktop paths and current Navivox docs. |

## Bottom line

Hermes Desktop should remain Navivox's product/architecture reference, not a parity checklist. The next high-leverage Navivox work is to harden and polish the Hermes-native mobile companion: session-first chat, real voice receipts, read-only capability surfaces, and strict redaction/readiness gates. Full Desktop parity should happen only surface-by-surface where Hermes Agent exposes a safe API and the mobile UX has clear value.
