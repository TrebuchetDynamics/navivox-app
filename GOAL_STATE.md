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
  **976 tests pass** (up from 927 on 2026-06-17; +49 new Hermes tests across
  the slices below).
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

## Remaining work

- Rich tool-progress cards (today tool events render as a plain system-text
  turn, not a dedicated tool-call/artifact model like the Gormes
  `NavivoxToolCall`).
- A real browser or Android smoke test of `HermesChatScreen` — every Hermes
  slice so far has been fixture/widget-tested plus one real (non-headless
  behavior) `flutter run -d web-server` compile pass, but never actually
  opened in a browser (Chrome automation has been unavailable in this
  environment throughout) or run against a live Hermes Agent API server.
- Android live smoke once a responsive Android target is available (same
  standing blocker as before): connect from emulator (`10.0.2.2:8642`) and
  physical device, verify continuous voice end-to-end against a live Hermes
  Agent API server.
- Nav-bar entry for `/hermes` (or flipping the app's default route to Hermes)
  is a deliberate later decision, not done here — see ADR 0007 delivery-slice
  note about setup-flow conversion coming before chat/session UI "rename."

## Honest caveat

`HermesApiChannel` and `HermesChatScreen` have been exercised against
fixture-driven fake HTTP/SSE transports and widget tests only, never a real
Hermes Agent API server. `HermesChatScreen` compiles and serves under a real
`flutter run -d web-server` build (this caught the JS-interop bug above) but
was not opened in an actual browser tab to eyeball rendering, since Chrome
browser automation was unavailable in this session. The concrete
`SecureHermesEndpointStore` has no dedicated test, matching the existing
convention for `SecureStorageDurableCredentialStore` (also untested
directly) — both are thin platform-plugin glue exercised through
higher-level tests instead.

## Loose ends

None outstanding for these slices: ADR 0007, the streaming client, the
native channel, the Hermes chat/session UI, setup-flow secure storage,
`/v1/runs` transport, and the full approval-decision set are all merged and
green. The next goal should either build rich tool-progress cards or get a
real browser/Android smoke test in front of `HermesChatScreen`.

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
