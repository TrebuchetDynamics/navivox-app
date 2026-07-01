# GOAL STATE — 2026-07-01

## Status

Active goal: **become a Hermes Agent mobile app with continuous voice
support** (see `docs/product/hermes-agent-interface-plan.md`,
`docs/adr/0006-hermes-agent-first-runtime.md`, and
`docs/adr/0007-native-hermes-channel-not-navivox-channel-adapter.md`).

The prior **durable-reconnect-credentials** goal (Gormes-era) reached its
non-device-gated ceiling on 2026-06-17 and is preserved below for history; it
is no longer the active goal now that the product direction is Hermes-first.

## Course correction (2026-07-01)

The Hermes interface plan originally proposed a `HermesNavivoxChannel
implements NavivoxChannel` transition seam so old Gormes-era screens (profile
contacts, config-admin, memory, profile seed, voice profiles, run-record)
could keep compiling. The owner rejected that: Navivox should adapt to
Hermes's actual surface, not force Hermes into a 35-member Gormes-shaped
interface, and should lean on `fathah/hermes-desktop`'s own architecture
(SSE parsing, capability-gated transport, session store shape, chat voice
input) as the reference. See ADR 0007.

## Verified gate (2026-07-01)

- Navivox: `flutter analyze` — no issues; `flutter test --concurrency=1` —
  **986 tests pass** (up from 927 on 2026-06-17; +59 new Hermes/platform tests
  across the slices below).
- A real `flutter run -d web-server` build (not just `flutter analyze`) was
  used to verify the Hermes web transport; see honest caveat below for what
  it did and did not confirm.

## Delivered slices (Hermes-first transition)

1. **Docs/domain reset** — ADR 0006, `hermes-agent-interface-plan.md`.
2. **Hermes API client fixtures** — `lib/core/hermes/` client/config/models/
   `HermesTransportPolicy`/SSE decoder, fixture-tested.
3. **ADR 0007 course correction** — no `NavivoxChannel` adapter; native
   `HermesChannel` instead.
4. **Streaming client + native Hermes channel** — `HermesApiClient.
   streamSessionChat` (new streaming POST transport, io/web/stub, plus
   `HermesSseEventDecoder.decodeStream`/`decodeJsonEventStream`); the native
   `lib/core/hermes/channel/` module (`HermesChannel`, `HermesChannelState`,
   `HermesApiChannel`) covering connect (health + capabilities + session
   list/create with a `navi-<timestamp>-<uuid>` client id), session select/
   create, `sendText` with streamed assistant-delta accumulation and
   post-stream reconciliation against `GET /api/sessions/{id}/messages`, and
   the continuous-voice run lifecycle (start/stage/submit/cancel/fail)
   reusing the already-generic `NavivoxVoiceRun` model end to end into a
   Hermes text turn.
5. **Hermes chat/session UI + continuous voice** — `lib/features/hermes_chat/`:
   `HermesVoiceRunController` and `hermesContinuousVoiceReplyToSpeak` (ports
   of the Gormes `VoiceRunController`/`continuousVoiceReplyToSpeak`, retyped
   to `HermesChannel`/`HermesChatTurn`), `hermesChannelProvider`, and
   `HermesChatScreen` (manual connect form, session picker, streamed
   transcript, composer, push-to-talk mic, and a continuous-voice toggle that
   loops capture → send → speak-via-TTS → re-arm hands-free). Wired as an
   additive `/hermes` route in the existing `ShellRoute` — reachable by URL,
   not yet in the bottom nav, and does not touch the Gormes-first
   `redirect`/`initialLocation` default. Caught and fixed a real bug that
   `flutter analyze` missed: `headers.forEach(request.setRequestHeader)` in
   `hermes_api_transport_web.dart` is an illegal JS-interop tear-off under
   the actual web compiler (both the pre-existing `_request` helper and the
   new streaming transport had it) — only surfaced by running a real
   `flutter run -d web-server` build.
6. **Setup-flow secure storage** — `lib/core/hermes/setup/`:
   `HermesEndpointStore` interface + `EmptyHermesEndpointStore` default
   (mirrors the existing `DurableCredentialStore` convention) and
   `SecureHermesEndpointStore` (base URL in `SharedPreferences`, API key only
   in `FlutterSecureStorage`). `hermesChannelProvider` auto-connects from any
   saved endpoint on creation; `HermesChatScreen` saves after a successful
   connect and clears on a new disconnect action.
7. **`/v1/runs` run transport** — `HermesApiClient.startRun`/`runEvents`
   (new GET-streaming transport)/`respondApproval`/`stopRun`.
   `HermesApiChannel.sendText` switches to run transport automatically when
   `HermesTransportPolicy.supportsRunsTransport` is true, decoding
   `message.delta` into the same assistant-turn accumulation, tool events as
   lightweight system turns (not a rich tool-card model yet), and
   `approval.request` through a new `approvalRequests` stream. Added real
   `stopActiveTurn()` (server `/v1/runs/{run_id}/stop`) and
   `respondToApproval()` (`once`/`deny` only — `session`/`always` not wired).
   `HermesChatScreen` gained the approval banner and stop control the
   interface plan requires before this transport can ship.
8. **Full approval-decision set** — `HermesApprovalDecision`
   (`once`/`session`/`always`/`deny`, `.name` maps directly to the wire
   `decision` field). `respondToApproval` on both `HermesChannel` and
   `HermesApiChannel` takes the enum instead of a boolean `approved` flag;
   `HermesChatScreen`'s approval banner now offers all four choices.
9. **Rich tool-progress cards** — `HermesToolCall` (name/status/preview/
   result) + a `HermesTurnKind` (`text`/`toolCall`) on `HermesChatTurn`.
   `HermesApiChannel` tracks each tool invocation by a `${runId}:${toolName}`
   call id (matching hermes-desktop's `chatToolEventFromRunEvent`
   synthesis — Hermes run events have no guaranteed-stable per-call id) so
   `tool.started`/`completed`/`failed` update one turn in place instead of
   duplicating it. `HermesChatScreen` renders these as a status card instead
   of plain text.
10. **Hermes nav-bar entry** — per owner decision, `/hermes` is now a
   first-class `AppShellDestination` in the desktop rail and mobile bottom
   nav (Memory moved to mobile overflow to keep the primary row compact).
   Explicit `/hermes` navigation is not redirected away just because no Gormes
   server is configured.
11. **Cross-platform endpoint hints** — the Hermes connect form now surfaces
   platform-specific base URL examples inline: local desktop/Linux/Windows/iOS
   simulator (`127.0.0.1`), Android emulator (`10.0.2.2`), and physical
   device LAN/VPN/Tailscale URL.
12. **Capability status strip** — connected Hermes chats now show a bounded
   capability summary sourced from `/v1/capabilities`: model, whether full
   run/tool-progress transport is enabled (or session-chat fallback), and the
   local-device voice boundary when Hermes realtime voice is not advertised.
13. **Real browser Hermes route smoke** — added Playwright smoke coverage for
   the Flutter web e2e bundle that opens `/#/hermes` in Chromium and verifies
   both the disconnected connect form/cross-platform endpoint hints and a
   connected Hermes session against the local e2e HTTP/SSE Hermes fake served
   by `serve_web.mjs`, covering the real web `HermesApiChannel` transport,
   capability strip, text exchange, approval prompt/response UI, stop control
   hitting `/v1/runs/{run_id}/stop`, streamed tool progress card,
   new-session creation, and the device-voice-transcript lifecycle rendering
   as a Hermes text turn in a real browser accessibility tree.
14. **Gormes screen deprecation notices** — a reusable `GormesLegacyNotice`
   banner ("This is a legacy Gormes screen. Navivox is moving to Hermes
   Agent." + an "Open Hermes" action) is wired into the Gormes-era top-level
   surfaces: `ProfileContactsScreen` (Chats), `ServersScreen`, `AgentsScreen`,
   `MemoryDashboardScreen`, and `ConfigScreen`. Purely additive — no Gormes
   functionality removed.
15. **Platform scaffolds + smoke runbook/build receipts** — added generated
   iOS and Windows platform folders (no overwrite of existing Android/web/
   Linux code) plus iOS microphone/speech-recognition usage descriptions for
   continuous voice, covered by `test/platform/platform_scaffold_test.dart`.
   Added `docs/runbooks/hermes-platform-smoke.md`. Current build gates: web
   e2e build passes; Android debug APK builds; Linux desktop build is blocked
   in this container by missing `libsecret-1>=0.18.4` for
   `flutter_secure_storage_linux`; Windows/iOS require host-platform runners.
16. **Host platform smoke runbook** — documented the unavailable-host gates:
   Ubuntu analyze/tests/web e2e build/Hermes browser smoke/Android debug APK/
   Linux release build with `libsecret-1-dev`, plus Windows desktop and iOS
   simulator builds on their own host runners. A GitHub Actions workflow draft
   was prepared but not shipped because the current push credential lacks
   GitHub `workflow` scope; host CI remains an owner follow-up.
17. **Hermes-first startup and README refresh** — fresh no-Gormes-server
   startup now lands at `AppRoutes.hermes` instead of the legacy Gormes
   setup path, using `AppRoutes.isHermesLocation()` so query/deep links do not
   fall through to legacy setup. Seeded legacy Gormes sessions still start at
   Chats for transition tests/users, and legacy setup remains available
   explicitly at `/setup`. `README.md`, `pubspec.yaml`, and `package.json` now
   describe the Hermes Agent companion app instead of saying Hermes Desktop is
   not the runtime target.
18. **`flutter build linux` unblocked without root** — this container has no
   passwordless `sudo`, so the missing `libsecret-1-dev`/`libgcrypt20-dev`/
   `libgpg-error-dev` (required by `flutter_secure_storage_linux`) couldn't be
   `apt-get install`ed system-wide. Worked around with `apt-get download`
   (no root needed) + `dpkg -x` into a local prefix, a rewritten `.pc` search
   path, and fixing the dev package's dangling `libsecret-1.so` symlink to
   point at the already-installed runtime `.so.0`. `ldd` confirms the built
   binary and plugin `.so` link the real system library at runtime — the
   local prefix is build-time-only. Full recipe in
   `docs/runbooks/hermes-platform-smoke.md`.

## Remaining work

- A live-browser smoke of `HermesChatScreen` against a real Hermes Agent API
  server — browser rendering of disconnected and connected Hermes UI is now
  covered, but live connect/stream/tool/approval behavior still uses the local
  e2e HTTP/SSE fake or unit/widget fixtures.
- Android live smoke once a responsive Android target is available (same
  standing blocker as before): connect from emulator (`10.0.2.2:8642`) and
  physical device, verify continuous voice end-to-end against a live Hermes
  Agent API server.
- Windows and iOS/macOS host-platform builds/smokes still need their own
  runners (Linux is now unblocked locally, see slice 18). Host CI workflow
  publishing still needs a credential with GitHub `workflow` scope.

## Honest caveat

`HermesApiChannel` and connected `HermesChatScreen` behavior have been
exercised against fixture-driven fake HTTP/SSE transports and widget tests
only, never a real Hermes Agent API server. `HermesChatScreen` compiles and
serves under a real Flutter web build (the earlier `flutter run -d web-server`
pass caught the JS-interop bug above), and the disconnected `/hermes` connect
form and connected Hermes session against the local e2e HTTP/SSE fake
(including approval prompt/response UI, stop control, streamed tool progress,
new session creation, and a device voice transcript submitted as a Hermes text
turn through the real web transport) now have Chromium Playwright smoke
coverage against the e2e web bundle. The concrete `SecureHermesEndpointStore`
has no dedicated test, matching the existing convention for
`SecureStorageDurableCredentialStore` (also untested directly) — both are thin
platform-plugin glue exercised through higher-level tests instead.

## Loose ends

None outstanding for these slices: ADR 0007, the streaming client, the
native channel, the Hermes chat/session UI, setup-flow secure storage,
`/v1/runs` transport, the full approval-decision set, rich tool-progress
cards, the Hermes nav-bar entry, cross-platform endpoint hints, the capability
status strip, the real-browser Hermes e2e smoke, Gormes deprecation notices,
the iOS/Windows scaffolds plus platform smoke runbook/build receipts, the
host-platform smoke runbook, Hermes-first startup, and README/package metadata
refresh are implemented and green locally where the platform is available.
The next goal should get a live Hermes Agent/API browser or Android smoke in
front of `HermesChatScreen`, or continue deeper conversion/hiding of remaining
Gormes-era internals.

---

## Prior goal (superseded): durable-reconnect-credentials — 2026-06-17

The durable-reconnect-credentials goal was driven to its
**non-device-gated ceiling**. Every slice that can be built and validated
without a responsive Android target is implemented, validated, and on `main`
(Navivox) or pushed (Gormes). The remaining work is **device-gated** and waits
on a responsive Android target — the same standing blocker as the Android
live-smoke item above.

Delivered slices (durable reconnect):

1. **Gormes endpoints + capability advertisement** — `gormes-agent` commit
   `5e6ef089f`, merged to `development` (`41009dcbe`).
2. **Client parse + readiness** — `reconnect_readiness_test.dart`.
3. **Readiness surfaced in gateway-status UI** — `navivox-app` `main`
   (`dd1af32`).
4. **Client issuance method** — `navivox-app` `main` (`f1d386b`).
5. **Issuance + store seam + connect wiring** — `navivox-app` `main`
   (`d3cb4f8`).

Remaining work (device-gated, BLOCKED): real Android secure-storage
`DurableCredentialStore`, ECDSA P-256 keystore challenge, `device_bearer`
silent reconnect, live end-to-end validation. This is Gormes-era work,
preserved on the `gormes` branch; it is not part of the active Hermes-first
goal.
