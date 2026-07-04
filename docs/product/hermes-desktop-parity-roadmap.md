# Hermes Desktop parity roadmap

Status: active roadmap. Navivox stays a Hermes Agent mobile companion first; full
Hermes Desktop parity is a staged target, not a ship gate for the current chat
MVP.

Source docs:

- [Hermes Desktop architecture and feature research](../research/hermes-desktop-architecture-research.md)
- [Hermes Agent interface plan](hermes-agent-interface-plan.md)
- [Hermes companion readiness audit](../runbooks/hermes-readiness-audit.md)
- [Hermes platform smoke checklist](../runbooks/hermes-platform-smoke.md)
- [ADR 0007 — native Hermes channel](../adr/0007-native-hermes-channel-not-navivox-channel-adapter.md)

## Current baseline

Implemented in `main`:

- `/hermes` main route and `HermesChatScreen`.
- Hermes API connect/session/chat over `HermesApiChannel`.
- HTTP/SSE transport, session list/new/rename/delete/fork, text turns.
- Local STT transcript submission as Hermes text voice.
- Approvals, stop, tool-progress UI, read-only jobs inventory, bounded diagnostics.
- Fake/live/provider browser smoke helpers.

Current readiness blockers:

- Real Android spoken microphone receipt.
- Windows/iOS/macOS native host receipts and published platform workflow.
- Hermes realtime/server audio unimplemented.
- Deferred Desktop-like surfaces: config/admin editing, memory UI, jobs/schedules
  admin, messaging gateways, persona/SOUL editing, attachments/media,
  files/context folders, raw logs export, and multi-endpoint/profile management.
- Polish/hardening: SSE reconnect/drop edge cases, offline/auth-expired UX,
  session search/grouping, queued follow-ups, and mobile approval/error/session
  sheet polish.

## Roadmap rules

1. Do not promote proxy evidence. Tests, APK hashes, workflow YAML, configured
   Hermes home, and dispatch-only workflow output are not readiness receipts.
2. Prefer hidden/read-only over half-wired admin UI when Hermes does not expose a
   safe API contract.
3. Every surface needs: capability detection, empty/offline/error states,
   redaction rules, tests, and a rollback/hide path.
4. Mutation surfaces need more: explicit Hermes API support, bearer-auth policy,
   confirmation UX for destructive actions, audit/redaction rules, and recovery
   copy.
5. Keep local STT voice useful while server/realtime audio remains separate and
   explicitly deferred.

## Phase 0 — receipt and release blocker closeout

Goal: make the existing chat companion evidence shippable without expanding
scope.

Work:

- Resolve GitHub credential `workflow` scope and publish
  `.github/workflows/hermes-platform-smoke.yml`.
- Collect successful `gh run view` job/artifact receipts for Ubuntu, Windows,
  macOS/iOS simulator, and optional hosted Android emulator jobs.
- Run provider-backed smoke with configured model/provider credentials.
- Run Android live-mic manual checklist on an audio-capable target.

Acceptance gate:

- `NAVIVOX_FAIL_ON_BLOCKERS=1 npm run hermes:readiness-audit` has no external
  receipt blockers for provider smoke, Android mic, native hosts, or platform
  workflow publication.
- The runbooks contain concrete command/job/artifact receipts, not just planned
  commands.

Rollback/hide behavior:

- If a receipt is missing, keep the readiness audit blocking and keep docs using
  `NOT COMPLETE` language.

## Phase 1 — chat companion hardening

Goal: make the implemented `/hermes` surface reliable under bad networks and
normal mobile use.

Work:

- Harden SSE reconnect/failure behavior: dropped stream, partial message,
  duplicate completion, late tool event, approval timeout, stop failure.
- Reconcile streamed transcript with session history after completion.
- Improve offline and auth-expired states for saved endpoint/API key.
- Keep bounded diagnostics copyable without raw logs, secrets, transcripts, or
  tool payloads.
- Preserve accessibility for session drawer, approval prompts, stop, voice, and
  error banners.

Acceptance gate:

- Focused `HermesApiChannel`/SSE tests cover stream edge cases.
- Browser fake Hermes smoke still passes.
- Provider text + deterministic transcript voice smoke passes when credentials
  are available.

Rollback/hide behavior:

- On unsupported capabilities or repeated transport failures, fall back to safe
  session-chat behavior or show recovery copy; do not expose broken run controls.

## Phase 2 — mobile voice receipts and audio strategy

Goal: finish mobile voice-to-text confidence before starting server audio.

Work:

- Capture real Android spoken phrase → Hermes text turn → provider reply → local
  TTS/re-arm receipt.
- Add clearer UI copy that local STT is the active voice path.
- Draft Hermes realtime/server audio API requirements only after the physical mic
  receipt is green.

Acceptance gate:

- `docs/runbooks/android/live-mic-smoke.md` has a current manual receipt.
- Readiness audit no longer blocks on real Android spoken microphone.
- Server/realtime audio remains deferred unless Hermes exposes a documented API
  and Navivox has tests against it.

Rollback/hide behavior:

- If device STT or audio target is unavailable, voice controls show unavailable
  state and keep text chat usable.

## Phase 3 — read-only Desktop parity surfaces

Goal: expose useful Desktop-like context without mutation risk.

Candidate surfaces:

- Models/providers: current selected model/provider and capability health.
- Skills/toolsets: enabled inventory from Hermes API.
- Jobs/schedules: read-only job inventory already started; expand details only.
- Health/capabilities: clearer endpoint readiness and version details.
- Bounded diagnostics: richer counts/statuses, still no raw logs or payloads.

Acceptance gate:

- Each surface is capability-gated and hidden or empty-state safe when absent.
- No secrets, transcript content, raw tool payloads, or private paths in UI/export.
- Widget/browser tests cover available, absent, loading, and error states.

Rollback/hide behavior:

- Missing capability means hidden/read-only-empty, not fake data or stale Gormes
  concepts.

## Phase 4 — admin surfaces, split by risk

Goal: add mutation only when Hermes has explicit safe APIs and Navivox has guard
rails.

Order:

1. Jobs/schedules admin: create/edit/delete with confirmations and dry-run where
   Hermes supports it.
2. Config/model/provider editing: only behind explicit Hermes config APIs;
   never edit files by guessing paths.
3. Memory UI: read/list/search before write/delete; mutation requires redaction
   and confirmation rules.
4. Persona/SOUL: only through explicit API or safe CLI/file contract.
5. Messaging gateways: status first, admin later; never expose provider secrets.
6. Attachments/media and files/context folders: require mobile-safe picker,
   upload limits, permission copy, and retention rules.
7. Raw logs/diagnostics export: last; requires redaction contract and explicit
   user action.

Acceptance gate for every mutation surface:

- Hermes capability advertises the endpoint and operation.
- Auth/authorization failure is safe and recoverable.
- Destructive actions require confirmation.
- Tests prove secret/path/transcript redaction.
- Surface can be disabled remotely by capability absence.

Rollback/hide behavior:

- Any failed contract or missing capability hides mutation UI while preserving
  read-only status where safe.

## Phase 5 — multi-endpoint/profile management

Status: local profile management implemented for the Hermes connect flow.
`SecureHermesEndpointStore` stores non-secret endpoint profile metadata/base URLs
in shared preferences and keeps per-profile API keys in secure storage. The
connect form renders saved profile chips that can select or forget an endpoint.

Remaining work:

- Remote revoke/status reporting if Hermes adds a revoke API.
- Optional explicit label editing beyond the current saved-profile metadata.
- Per-endpoint session cache boundaries if Navivox later caches server sessions
  locally.
- Keep old Gormes Profile contacts out of Hermes terminology.

Acceptance gate:

- API keys remain in secure storage only.
- Switching endpoints cannot leak sessions, diagnostics, or secrets across
  endpoint boundaries.
- Forget endpoint removes local key/metadata and reports remote revoke status
  only when a remote revoke API exists.

Rollback/hide behavior:

- If endpoint identity is ambiguous, keep profile chips hidden and show setup
  copy.

## Phase 6 — Desktop parity review gate

Goal: decide whether Navivox should pursue parity surface-by-surface or remain a
focused companion.

Gate checklist:

- Phase 0 receipts are green and current.
- Chat/voice companion usage is stable under real Android and provider runs.
- Every read-only/admin surface has explicit Hermes API backing.
- Security review covers secrets, logs, transcripts, tool payloads, files, and
  destructive actions.
- UX review confirms mobile value; Desktop-only install/update/office workflows
  may remain out of scope.

Outcome options:

- Promote a surface to MVP if it has mobile value and passes its gate.
- Keep it read-only if mutation risk is higher than mobile value.
- Keep it deferred if Hermes lacks API support or safe mobile semantics.
