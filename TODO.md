# Navivox TODO

[RESOLVED] Navivox-side Termux-to-Navivox pairing handoff without camera — 2026-05-24
  resolved: 2026-05-24
  result: Android now accepts `navivox://connect?...` VIEW intents and text/plain ACTION_SEND payloads, forwards initial and foreground intents into Flutter, fills the setup form through existing connect-info parsing, preserves explicit `websocket_url`, and keeps tokens out of notices/logging. Gormes still needs the Termux `am start ...` command-side launcher.

[PLANNED] Stable Gormes gateway identity for Pairing handoff — 2026-05-25
  problem: accepted durable gateway metadata semantics require a stable Gateway identity distinct from Profile contact `server_id`, but `/v1/navivox/status` currently reports bind/port and profile routing while `NavivoxGatewayStatus` has no gateway identity field.
  evidence: Navivox Profile contacts carry `server_id`, but that scopes Profiles inside the gateway and defaults to `navivox-gateway`; Gormes status currently includes `bind_host`, `port`, `exposure_mode`, `auth_mode`, and `profile_routing`, not a stable gateway identity; Navivox durable gateway storage is not implemented yet.
  acceptance: define and advertise a stable opaque-public `gateway_id` (or equivalent clearly named Gateway identity), generated once with randomness and persisted in Gormes config, plus a separate non-authoritative human-readable gateway label that defaults to bland copy like `Gormes gateway` and may become operator-editable later; keep Profile contact `server_id` scoped to profile/contact routing; descriptors may carry Gateway identity/label only as non-authoritative hints; Navivox trusts Gateway identity only after authenticated status/capabilities confirms it; Navivox updates existing gateway metadata by authenticated Gateway identity even when base URL/port changes; label changes never affect identity, key alias, or reconnect proof; fallback identity is normalized base URL origin when Gateway identity is absent; tokens, usernames, machine names, display labels, and paths are never part of identity.
  owner: Navivox app owner / Gormes gateway owner
  next check: durable gateway metadata slice.

[PLANNED] Pairing handoff source trust classification — 2026-05-25
  problem: accepted Pairing handoff semantics trust package-targeted direct Android VIEW from Gormes more than generic text share, but Navivox currently forwards only raw payload strings from Android and `NavivoxConnectIntentSource` emits `SetupQrImageImport` without source/action metadata.
  evidence: Android `MainActivity.connectPayloadFrom()` accepts both `Intent.ACTION_VIEW` and `Intent.ACTION_SEND`; Flutter `NavivoxConnectIntentSource.initialImport()` / `.imports` parse both into identical `SetupQrImageImport`; setup currently fills fields for both and has no way to decide auto-connect vs fill-and-wait by source.
  acceptance: carry handoff source metadata from Android to Flutter; package-targeted `navivox://connect` VIEW may auto-connect under no-active-gateway rules; ACTION_SEND text/plain and QR/image imports always fill fields and wait for operator confirmation; tests cover both paths without leaking tokens.
  owner: Navivox app owner / Android owner
  next check: Pairing handoff auto-connect slice.

[PLANNED] Pairing handoff bridge-stopped recovery copy — 2026-05-25
  problem: accepted Pairing handoff semantics should not retry indefinitely when the local Termux bridge is stopped; recovery should steer the operator to re-run `gormes navivox pair` while keeping imported fields populated and tokens hidden.
  evidence: current setup connection failure copy says `Run gormes navivox connect-info on the host and retry`; tests assert that connect-info guidance is shown without token leakage; there is no Pairing-handoff-specific failure state yet.
  acceptance: for direct Pairing handoff auto-connect failure, show retry action/copy to re-run `gormes navivox pair`; do not infinite retry; keep fields populated; keep token obscured and absent from notices/logs/transcripts/screenshots; preserve generic connect-info recovery for manual/register gateway flows where appropriate.
  owner: Navivox app owner / Gormes gateway owner
  next check: Pairing handoff auto-connect slice.

[PLANNED] Pairing handoff auto-connect and active-gateway confirmation — 2026-05-25
  problem: accepted Pairing handoff semantics allow direct Android handoff to auto-connect only when Navivox is still in setup/no-active-gateway; foreground handoffs while connected should ask confirmation before any new gateway probe.
  evidence: router currently redirects to setup when `channel.state.servers.isEmpty` and away from setup when servers exist; `NavivoxChannelState` exposes `hasServers`, `activeServer`, and selected Profile contact state; setup imports currently fill fields but do not auto-connect or branch foreground handoff confirmation by active gateway.
  acceptance: initial or foreground Android Pairing handoff auto-connects only when no active gateway/server exists or setup is active without servers; if an active gateway exists and the handoff target is unknown/different, show confirmation before probing or switching; different authenticated Gateway identity creates/updates a separate gateway record instead of replacing the current gateway, and becomes active only after confirmation when another gateway is active; same-gateway refresh may replace the existing credential, update connection metadata, and reconnect without confirmation only after a successful authenticated Pairing handoff/probe proves the same Gateway identity; Navivox and Gormes keep one active credential per `gateway_id` plus app install identity, so rotation/re-pair replaces the prior active credential; Gormes may keep redacted audit history with install ID, operator-editable safe device label, created/revoked timestamps, scopes, and last-used time, but diagnostic export should omit IP addresses, user agents, and device fingerprints by default; Gormes must hard-delete active secret/key material and never retain bearer tokens/private secrets in audit records; default device label is bland copy like `Navivox Android` and must not auto-include Android model, username, account, hostname, or other device-derived identifiers unless the operator explicitly edits/accepts it; failed proof leaves existing gateway metadata and credential untouched; failed auto-connect leaves fields populated with no token leakage.
  owner: Navivox app owner / Gormes gateway owner
  next check: Pairing handoff auto-connect slice.

[PLANNED] Pairing handoff setup-intent routing — 2026-05-25
  problem: accepted Pairing handoff semantics allow Gormes to suggest a high-level setup landing target, but Navivox currently parses only connection fields in setup import and does not route post-connect based on setup intent.
  evidence: Gormes `navivox pair` emits `setup_handoff=true`, `setup_sections=provider,model,workspace,channels`, and `setup_entry_screen=setup.provider`; Navivox capability parsing exists and Gormes advertises config-admin endpoints, but `GatewayNavivoxChannel.sendConfigSet()` still reports config editing unavailable and the Config UI is not yet wired to Gormes config-admin.
  acceptance: carry setup intent through Pairing handoff as a suggestion only; after successful connection, capability-gate any setup/config destination against the Gormes capability document; if unsupported, land on normal Profile contacts/config entry; never enable config mutation from descriptor fields alone.
  owner: Navivox app owner / Gormes gateway owner
  next check: config-admin or Pairing handoff routing slice.

[PLANNED] Optional Pairing handoff and reconnect Profile contact routing — 2026-05-25
  problem: accepted Pairing handoff and durable reconnect semantics allow Navivox to prefer a Profile contact target, but Navivox setup import currently fills connection fields only and does not carry a post-connect route target through setup or reconnect.
  evidence: `NavivoxPairingDescriptor` already parses optional `server_id` and `profile_id`, but `SetupQrImageImport` drops them; Gormes `navivox pair` currently emits setup handoff fields such as `setup_entry_screen` but no `profile_id`; durable connection metadata/reconnect is not implemented yet.
  acceptance: if a Pairing handoff includes `server_id`/`profile_id`, Navivox treats them as optional route intent only after successful connection; durable reconnect may remember the last active Profile contact as non-secret metadata; open a requested or last active Profile contact only when the reconnected gateway reports that exact Profile contact, otherwise land on the Profile contact list; never invent a Profile contact from descriptor or persisted metadata; do not block Pairing handoff/reconnect completion on this route target.
  owner: Navivox app owner / Gormes gateway owner
  next check: durable Pairing handoff/reconnect routing slice.

[PLANNED] Durable Navivox connection credential storage — 2026-05-25
  problem: accepted Pairing handoff semantics should create/update durable Gormes gateway metadata after successful connection, but Pairing handoff tokens are bootstrap-only and Navivox currently has no secure device credential storage or gateway-issued durable credential protocol.
  evidence: setup/connect code keeps tokens in memory; `shared_preferences` is present for non-secret voice settings only; there is no secure storage dependency, token vault abstraction, device credential issuance endpoint, or reconnect proof flow yet.
  acceptance: keep Pairing handoff tokens short-lived/bootstrap-only; after successful authenticated setup on Android, durable credential issuance happens automatically immediately after authenticated connect plus capability/transport proof and before any chat turn, with clear non-modal post-connect notice/settings status such as `Reconnect saved for this gateway` and `Reconnect: saved on this Android install`, never showing token or credential IDs in normal UI; credential IDs may appear only in advanced diagnostics/export and should be redacted or truncated by default for support correlation without broad cross-context leakage; if issuance fails, Pairing handoff still completes because Navivox connected successfully, chat may continue session-only, and Navivox shows `Connected for this session; reconnect not saved` recovery copy without undoing the active connection; Navivox may perform one bounded automatic retry for transient issuance failure, then stops and leaves manual retry in gateway/settings, with no infinite retry loop; manual retry may use existing active session auth when still connected and scopes/capabilities allow issuance, otherwise it requires a new Pairing handoff; Gormes issues a revocable/rotatable Navivox device credential through a separate mutating endpoint, not `/v1/navivox/status`, bound to authenticated Gateway identity and a Navivox-generated random non-secret app install identity stored with non-secret metadata, not secure storage and not a hardware/user fingerprint; the endpoint accepts Pairing handoff token auth for initial issuance/re-pair and existing durable credential auth only for self-rotation of that install, not minting extra active credentials for other installs; self-rotation re-evaluates current gateway policy and caps new scopes to the previous credential scopes so rotation cannot expand privileges, while Pairing handoff re-pair can issue current default scopes, then invalidates the one-time Pairing handoff token when used or forces it to expire very soon; reinstalling Navivox creates a new install identity and therefore a new credential while old credentials remain server-revocable; static-token/admin auth remains separate legacy/non-Pairing semantics; gold-standard credential is one device public/private key challenge per Gormes gateway, with each private key kept in platform keystore/secure storage under an alias based on authenticated `gateway_id` when available, using a temporary local record ID only before Gateway identity proof, and each public key registered only with that gateway; challenge auth uses Gormes-issued short-TTL single-use nonces rather than signing arbitrary request bodies, with Navivox signing canonical JSON bytes, not ad-hoc concatenated strings, containing stable fields such as gateway ID, install ID, credential ID, nonce, issued/expiry times, intended action, and audience; Gormes/Navivox tests should include fixed signature vectors; Gormes consumes a nonce on successful auth, expires unused nonces quickly, rejects reuse, and may mark repeated reuse as suspicious; REST API calls and WebSocket auth should use short-lived non-persisted access/session tokens minted through the REST challenge flow and scoped to the gateway, credential, scopes, and stream connection where applicable; durable credential issuance and reconnect may use plain HTTP only for loopback/local bridge, while non-loopback exposure requires HTTPS or an authenticated private-network posture such as Tailscale/WireGuard as advertised by capability/status transport security metadata; Navivox refuses durable credential issuance/reconnect by default on insecure non-loopback HTTP instead of warning-only, though session-only Pairing handoff/manual connection may remain available for explicit recovery; Android/Termux same-device transport must use the explicit authenticated Pairing handoff `base_url`/`websocket_url` as connection authority and must not assume app loopback reaches Termux loopback or rewrite to loopback for persistence/security classification unless authenticated gateway capability/status confirms the exposure mode; descriptor URLs may be used only for preflight obvious-insecure checks, while final durable credential eligibility and transport-security classification must come from authenticated status/capabilities because descriptors can be stale or forged; Gormes status/capabilities should expose detailed transport-security fields plus a simple effective enum/gate, e.g. `effective_security` as `loopback`, `private_network`, `tls`, or `insecure`, `exposure_mode`, TLS flag, private-network provider such as Tailscale/WireGuard, and `durable_credentials_allowed`; REST access tokens default to about 5 minutes, while WebSocket stream tokens are single-connection-attempt tokens with no more than about 60 seconds to open the stream; active WebSocket lifetime is controlled by credential revocation/session close after handshake; Navivox repeats the challenge flow when tokens expire; first slice uses short TTL plus underlying credential revoke to invalidate minted tokens, not individual token revocation, avoiding per-request nonce signing and private-key signing inside WebSocket subprotocol/header constraints; key aliases never include base URLs, tokens, usernames, machine names, or paths; first durable persistence slice must include `/v1/navivox/capabilities` advertisement for durable credential support, including separate mutating credential issuance endpoint, supported auth methods such as `pairing_token` plus `device_key_challenge` or interim `device_bearer`, list/revoke endpoints, scope support, and explicit web durable reconnect unsupported/disabled status; credential scope storage in the Gormes credential record defaults the initial Android credential to the current Navivox capability set or a coarse `navivox` scope; include a minimal authenticated Gormes API to issue/list/revoke Navivox device credentials, capability-gated for Navivox clients and scoped so first-slice Navivox can view/revoke its own install while Gormes CLI/admin may list/revoke all installs; polished all-device management UI can follow later; revocation prevents all future auth immediately and should close active WebSocket streams authenticated by the revoked credential in the same slice when bounded, otherwise active stream closure is an explicit follow-up blocker before claiming full revocation semantics; Android durable reconnect is silent by default after app start, relying on platform keystore protection; config-admin actions do not require fresh Pairing handoff or per-action re-auth in the first slice and instead rely on credential scopes plus existing Gormes policy, with biometrics/device-unlock or re-auth for sensitive config/secret edits reserved for a future explicit high-security setting; first implementation should go straight to ECDSA P-256 with SHA-256 keypair challenge through a small Android-native keystore MethodChannel for non-exportable private-key generation/signing if Android secure key APIs are feasible from Flutter/native bridge, with RSA-PSS fallback only if Android compatibility testing forces it; Navivox sends public keys to Gormes as JWK protocol payloads with algorithm metadata such as `kty: EC`, `crv: P-256`, base64url `x`/`y`, `alg: ES256`, and optional Gormes-assigned `kid`; a simple bearer device token is allowed only as a bounded first slice if keypair integration is the schedule risk, explicitly marked interim in capabilities/docs, and stored only in platform secure storage; avoid broad secure-storage dependencies for the first Android keypair slice unless the native bridge proves impractical; future iOS support should use a parallel Keychain/Secure Enclave adapter; Navivox never stores device credentials in `shared_preferences`; persist non-secret Gateway identity/display/base URL/explicit WebSocket URL/last-connected/capability-summary metadata through a small repository abstraction backed initially by `shared_preferences`; durable credential metadata belongs only to gateway auth/admin state and local gateway metadata, never Gormes memory, Profile contact state, Transcript surface, sessions, run records, or agent-visible records; reconnect loads metadata plus secure credential, authenticates `/v1/navivox/status`, proves the same Gateway identity before updating metadata, and falls back to a new Pairing handoff if the credential is missing/expired/revoked even when Gateway identity matches; when the same `gateway_id` is restored without the public-key credential registry, Navivox keeps non-secret metadata and treats it as a known gateway that needs a new Pairing handoff; credential failure never auto-deletes gateway metadata, only explicit `forget gateway` does; if the Gateway identity changed after Gormes config reset, Navivox treats it as a different gateway; Gormes config reset invalidates durable credentials unless the operator explicitly preserves/restores both Gateway identity and credential registry during backup or migration; normal Gormes backup/export may include opaque-public Gateway identity by default for same-gateway restore/migration, while reset/regenerate identity must be explicit; Gormes backup/export must not include the credential registry by default, and should include it only in an explicit `preserve paired Navivox devices` mode; Flutter web gets no durable credential issuance or silent durable reconnect initially and may keep only session credentials plus non-secret metadata unless a future explicit opt-in/risk-copy design is accepted; Navivox `forget gateway` tries remote revocation for only this app install credential by default when reachable, always deletes local credential and non-secret metadata, and reports when remote revoke is pending/unconfirmed without retaining local secrets; normal UI does not offer a separate `forget local only` action because it invites leftover server grants, though emergency/debug wording can explain local deletion if remote revoke is unreachable; all-device revoke is reserved for Gormes CLI/admin or future management UI, and first durable credential slice should include Gormes CLI emergency commands to revoke this install, revoke by credential ID, and revoke all Navivox credentials for the gateway, with confirmation prompts for destructive actions and `--yes` support for scripted exact/broad revokes; Navivox UI `forget gateway` uses its own confirmation sheet; add tests proving secrets are not written to shared preferences, browser local storage, logs, routes, notices, screenshots, or transcript state.
  owner: Navivox app owner / Gormes gateway owner / security owner
  next check: durable connection credential protocol slice.

[PLANNED] Android release signing config — 2026-05-24
  problem: Android release builds still use Flutter's debug signing config, which is acceptable for local smoke runs but not for distributable APK/AAB artifacts.
  evidence: `android/app/build.gradle.kts` keeps `release.signingConfig = signingConfigs.getByName("debug")` so `flutter run --release` remains easy while no release keystore policy is committed.
  acceptance: add a non-secret release signing configuration that reads keystore path/passwords from local properties or CI secrets, document local setup, verify `flutter build apk --release` or `flutter build appbundle`, and keep keystore material out of git.
  owner: Navivox app owner / release owner
  next check: first Android distribution slice.

[PLANNED] Navivox config-admin channel wiring — 2026-05-24
  problem: the Config UI can draft and confirm edits, but `GatewayNavivoxChannel.sendConfigSet()` and `.sendConfigSecretSet()` still emit local unavailable messages even though Gormes now advertises stable config-admin endpoints.
  evidence: updated `../gormes-agent/internal/channels/navivox/capabilities.go` advertises `/v1/navivox/config-admin`, `/schema`, `/diff`, `/validate`, and `/apply`; `../gormes-agent/internal/channels/navivox/config_admin_test.go` proves secrets are redacted and invalid apply is non-mutating, but Navivox app has no low-level config-admin client methods and no channel adapter for the existing `ConfigApplyDispatcher`.
  acceptance: add typed `NavivoxGatewayClient` methods for schema/get/diff/validate/apply, preserve 422 validation payloads instead of collapsing them into generic transport errors, capability-gate the Config apply affordance, keep secret values out of transcript/log/UI echoes, and add channel + widget tests for valid apply, validation error, pending restart, and reload-applied states.
  owner: Navivox app owner / Gormes gateway owner
  next check: next config-admin slice.

[PLANNED] Navivox voice-profile settings wiring — 2026-05-24
  problem: continuous voice uses Profile contact voice health and local command-mode settings, but the app does not yet expose Gormes' profile-scoped voice-profile read/validate surface.
  evidence: updated `../gormes-agent/internal/channels/navivox/capabilities.go` advertises `/v1/navivox/voice-profiles` and `/v1/navivox/voice-profiles/validate`; `../gormes-agent/internal/channels/navivox/voice_profiles_test.go` proves provider matrices, credential status refs, and validation errors are redacted, but Navivox app only parses capability metadata and does not provide a UI/channel adapter for those endpoints.
  acceptance: add typed client reads/validation for voice profiles, capability-gate voice settings affordances, surface provider matrix and credential status without secret leakage, keep continuous voice tap-to-capture semantics unchanged, and add tests for valid profile, invalid provider, missing credential fallback, and recovery-copy interactions.
  owner: Navivox app owner / Gormes gateway owner
  next check: next voice-profile settings slice.

[PLANNED] Navivox approval response protocol — 2026-05-24
  problem: Navivox renders approval-required events, but `GatewayNavivoxChannel` cannot resolve approve/deny choices durably; current approval actions still report that tool approvals are unavailable.
  evidence: updated Gormes Navivox capabilities advertise `approval_required` events, and `../gormes-agent/internal/channels/navivox/channel.go` can broadcast approval requests, but no Navivox approve/deny HTTP or stream message surface is advertised for returning the operator decision.
  acceptance: wait for Gormes to advertise a stable approve/deny action or endpoint, add a typed client/channel adapter only for that advertised surface, preserve risk copy and approval IDs, reject stale approvals safely, and add tests for approve, deny, stale/missing ID, and no-secret logging.
  owner: Navivox app owner / Gormes gateway owner
  next check: next safety/approval protocol slice.

[PLANNED] Gateway session and run-record UI wiring — 2026-05-24
  problem: Gormes exposes Navivox session snapshots and voice/turn run records, and Navivox now has low-level typed client reads, but the Chat/Voice UI still relies on local transcript state for run history and diagnostics.
  evidence: updated `../gormes-agent/internal/channels/navivox/capabilities.go` advertises `/v1/navivox/sessions`, `/v1/navivox/sessions/{session_id}`, and `/v1/navivox/run-records/{run_id_or_session_id}`; `NavivoxGatewayClient.sessions()`, `.session()`, and `.runRecord()` are covered in `test/core/gateway/navivox_gateway_protocol_test.dart`, but no Transcript surface or Voice diagnostics flow consumes them yet.
  acceptance: capability-gate any history/diagnostics affordance, keep raw transcripts/evidence bounded to Gormes' redacted read model, add UI tests for loading/error/empty states, and preserve local continuous voice behavior when run-record reads fail.
  owner: Navivox app owner / Gormes gateway owner
  next check: next Voice diagnostics or Transcript history slice.

[PLANNED] Composer attachment upload and media picker wiring — 2026-05-24
  problem: the Transcript surface exposes Telegram-style attachment rows, but local file upload, photo/video picking, workspace-file selection, and Gormes gateway handoff are not durable product behavior yet.
  evidence: `lib/features/chat/transcript_composer_presentation.dart` exposes upload/media rows as disabled-copy affordances; current composer tests verify the sheet and row presentation but not upload dispatch. Updated Gormes Navivox capabilities advertise attachments as unavailable until `/v1/navivox/uploads`, with raw local paths rejected.
  acceptance: wait for Gormes to advertise opaque upload IDs and a non-empty MIME allowlist, keep secrets/local file paths out of logs, add tests for operator intent emission, and wire upload/media rows only when the capability document enables `/v1/navivox/uploads`.
  owner: Navivox app owner / Gormes gateway owner
  next check: next attachment/upload slice.

[PLANNED] Navivox Profile contact create-from-seed UI wiring — 2026-05-24
  problem: the Agents empty state can explain missing profile creation/import support, but Navivox app does not yet have a durable Operator intent or channel method for Gormes' advertised create-from-seed flow.
  evidence: updated `../gormes-agent/internal/channels/navivox/capabilities.go` advertises `/v1/navivox/profile-seed` and supported action `create_from_seed`; Navivox now parses the capability document and `NavivoxGatewayClient.profileSeed()` can call the endpoint, but `NavivoxChannel` still has no create-from-seed method and Agents still shows an unavailable sheet.
  acceptance: capability-gate the Agents create/import UI on `create_from_seed`, add a local Operator intent or channel method, keep secrets/local paths/connect-info tokens out of logs, invoke the tested `NavivoxGatewayClient.profileSeed()` path, refresh Profile contacts after success, and keep dashboard `/api/profiles` hidden from Navivox clients.
  owner: Navivox app owner / Gormes gateway owner
  next check: next profile-management slice.

[RESOLVED] Gormes Navivox API capability contract — 2026-05-24
  resolved: 2026-05-24
  evidence: updated `../gormes-agent/internal/channels/navivox/capabilities.go` and `capabilities_test.go` add authenticated `/v1/navivox/capabilities`, link it from `/v1/navivox/status`, advertise `/healthz`, `/v1/navivox/profile-seed`, attachment unavailability, voice profile support, canonical `/v1/navivox/stream`, and dashboard-profile API deprecation.
  validation: Navivox app now parses `capabilities_url` plus the capability document shape in `test/core/gateway/navivox_gateway_protocol_test.dart`; full app validation remains green.
  owner: Navivox app owner / Gormes gateway owner

[RESOLVED] Web setup accessibility blocks keyboard/screen-reader connect flow — 2026-05-22 18:55 CST
  resolved: 2026-05-22 19:25 CST
  evidence: setup now exposes `Gateway base URL field`, `Pairing token field`, `Import pairing QR image`, `Show pairing token`, and `Connect and talk` in the Flutter web accessibility tree after semantics activation; `agent-browser find text "Connect and talk" click`, `find text "Import pairing QR image" click`, and `find text "Show pairing token" click` all exited 0; pressing Enter in the token field fired `/v1/navivox/status`.
  validation: `flutter analyze`, `flutter test`, `flutter build web`, and browser QA against `http://127.0.0.1:8765/#/setup` passed for this slice.
  owner: Navivox app owner / Mineru

[BLOCKED] Android continuous voice live phrase capture — 2026-05-22 18:39 CST
  blocker: connected emulator `emulator-5554` is listed by ADB but shell commands still time out, so this host cannot install the APK, query Android speech recognizers, grant microphone permission, or capture a real voice phrase.
  evidence: `build/app/outputs/flutter-apk/app-debug.apk` exists at 184870689 bytes; `adb devices -l` lists `emulator-5554`; `timeout 5s adb -s emulator-5554 shell true` exits 124 on the second retry; `timeout 8s adb -s emulator-5554 shell cmd package query-services -a android.speech.RecognitionService` exits 124 on the second retry.
  unblocks when: a responsive physical USB-debuggable Android device or healthy emulator is available for `adb shell`, APK install, speech-recognizer query, microphone permission grant, and one short active-profile chat phrase capture.
  owner: local Android test environment / Juan.
  workaround/pivot: keep the release handoff/checklist as the source of truth and rerun the same smoke sequence on a responsive Android target; preserve unrelated profile-management WIP.
  next check: next development-loop iteration with a responsive Android target.

[BLOCKED] Android continuous voice device smoke validation — 2026-05-22 17:55 CST
  blocker: connected emulator `emulator-5554` is listed by ADB but shell commands time out, so this host cannot validate microphone permission or real device STT capture.
  evidence: `adb devices -l` lists `emulator-5554`; `timeout 5s adb -s emulator-5554 shell true` exits 124; `timeout 5s adb -s emulator-5554 shell getprop sys.boot_completed` exits 124.
  unblocks when: a responsive Android emulator or physical USB-debuggable device is available for `adb shell` plus Navivox APK install/run.
  owner: local Android test environment / Juan.
  workaround/pivot: document a repeatable Android continuous-voice smoke checklist and keep code-level Flutter gates green.
  next check: next Navivox Android smoke iteration.

[RESOLVED] Commit/push screenshot iteration 1 repeated agent-list message slice — 2026-05-22 16:23 CST
  resolved: 2026-05-22 16:45 CST
  evidence: `flutter analyze`, `flutter test`, and `git diff --check` all passed after fixing stale E2E/control finders, the profile-contact back-button expectation, and the README setup screenshot golden.
  owner: Navivox app owner / Mineru

[BLOCKED] Commit/push Transcript surface plan and context updates — 2026-05-20 20:56 CST
  blocker: `navivox-app` is untracked inside parent repo `/home/xel/git/sages-openclaw`, so committing only plan/context files would add a partial project tree.
  evidence: `git rev-parse --show-toplevel` => `/home/xel/git/sages-openclaw`; `git status --short -- /home/xel/git/sages-openclaw/workspace-mineru/navivox-app` => `?? workspace-mineru/navivox-app/`.
  unblocks when: Juan or owning agent decides whether `navivox-app` should be tracked whole, moved to its own repo, added as a submodule, or ignored.
  owner: Juan / repository owner
  workaround/pivot: saved the implementation plan and context wording without staging a partial commit; wait for ownership decision before commit/push.
  next check: 2026-05-21 10:00 CST

[BLOCKED] Run Subagent-Driven Development execution — 2026-05-20 21:02 CST
  blocker: current pi harness has no Agent/subagent dispatch tool, so fresh implementer/spec-review/code-review subagents cannot be launched.
  evidence: available tool surface in this session is file/command tools (`read`, `bash`, `edit`, `write`, `multi_tool_use.parallel`); no Agent/TodoWrite dispatch tool is exposed.
  unblocks when: this work runs in a subagent-capable harness, or Juan approves switching to inline execution.
  owner: harness / Juan
  workaround/pivot: prepared Task 1 subagent dispatch packet at `docs/superpowers/plans/2026-05-20-transcript-surface-task1-subagent-packet.md`.
  next check: 2026-05-21 10:00 CST

[BLOCKED] Commit/push Voice run lifecycle spec — 2026-05-21 08:34 CST
  blocker: `navivox-app` is untracked inside parent repo `/home/xel/git/sages-openclaw`, so committing the Voice run spec would require adding a partial project tree.
  evidence: `git status --short -- workspace-mineru/navivox-app` => `?? workspace-mineru/navivox-app/`.
  unblocks when: Juan or owning agent decides whether `navivox-app` should be tracked whole, moved to its own repo, added as a submodule, or ignored.
  owner: Juan / repository owner
  workaround/pivot: saved design spec at `docs/superpowers/specs/2026-05-20-voice-run-lifecycle-design.md` without staging a partial commit.
  next check: 2026-05-21 10:00 CST

[BLOCKED] Commit/push Voice run lifecycle implementation plan — 2026-05-21 08:39 CST
  blocker: `navivox-app` is untracked inside parent repo `/home/xel/git/sages-openclaw`, so committing the implementation plan would require adding a partial project tree.
  evidence: `git status --short -- workspace-mineru/navivox-app` => `?? workspace-mineru/navivox-app/`.
  unblocks when: Juan or owning agent decides whether `navivox-app` should be tracked whole, moved to its own repo, added as a submodule, or ignored.
  owner: Juan / repository owner
  workaround/pivot: saved implementation plan at `docs/superpowers/plans/2026-05-21-voice-run-lifecycle.md` without staging a partial commit.
  next check: 2026-05-21 10:00 CST

[BLOCKED] Commit/push Voice run lifecycle implementation — 2026-05-21 08:53 CST
  blocker: `navivox-app` is untracked inside parent repo `/home/xel/git/sages-openclaw`, so committing the validated implementation would require adding a partial project tree.
  evidence: `git status --short -- workspace-mineru/navivox-app` => `?? workspace-mineru/navivox-app/`; full `flutter test` passed locally after the implementation.
  unblocks when: Juan or owning agent decides whether `navivox-app` should be tracked whole, moved to its own repo, added as a submodule, or ignored.
  owner: Juan / repository owner
  workaround/pivot: completed and validated the client-local Voice run lifecycle implementation without staging a partial commit.
  next check: 2026-05-21 10:00 CST

[BLOCKED] Commit/push navivox-loop iteration 1 voice failure-reason slice — 2026-05-21 09:01 CST
  blocker: `navivox-app` is untracked inside parent repo `/home/xel/git/sages-openclaw`, so committing the validated iteration slice would require adding a partial project tree.
  evidence: `git status --short -- workspace-mineru/navivox-app` => `?? workspace-mineru/navivox-app/`; `flutter analyze`, `flutter test`, and `git diff --check -- workspace-mineru/navivox-app` all exited 0 in this iteration.
  unblocks when: Juan or owning agent decides whether `navivox-app` should be tracked whole, moved to its own repo, added as a submodule, or ignored.
  owner: Juan / repository owner
  workaround/pivot: completed the timeout failure-reason slice and left it unstaged.
  next check: 2026-05-21 10:00 CST

[BLOCKED] Navivox full gate for Pi delivery-loop extension — 2026-05-21 08:52 CST
  blocker: full repo gate is red from pre-existing Navivox app test/model drift and unrelated root whitespace outside the extension slice.
  evidence: `flutter analyze` reports undefined getter `voiceCapability` in `app/test/core/channel/gateway_navivox_channel_test.dart:149-152`; `flutter test` reports `loads profile contacts from snapshot and applies gateway updates` expected `available`, actual `unavailable`; unscoped `git diff --check` reports trailing whitespace in `.sisyphus/plans/gormes-port-master-plan.md:3` and `:5`.
  unblocks when: Navivox voice capability expectations are reconciled with `NavivoxProfileContact`, and unrelated root whitespace is fixed or excluded by an agreed gate scope.
  owner: Navivox app owner / root workspace owner
  workaround/pivot: completed the extension slice with focused contract test and scoped `git diff --check -- workspace-mineru/navivox-app`; did not modify unrelated app/root WIP.
  next check: 2026-05-21 10:00 CST
