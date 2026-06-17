# GOAL STATE — 2026-06-17

## Status

The durable-reconnect-credentials goal has been driven to its
**non-device-gated ceiling**. Every slice that can be built and validated
without a responsive Android target is implemented, validated, and on `main`
(Navivox) or pushed (Gormes). The remaining work is **device-gated** and waits
on a responsive Android target — the same standing blocker as the Android
live-smoke item.

## Verified gate (2026-06-17)

- Navivox: `flutter analyze` — no issues; `flutter test --concurrency=1` —
  **927 tests pass**.
- Gormes: `go test ./internal/adapters/channels/navivox/...` — **76 pass**;
  `go vet` and `gofmt` clean.

## Delivered slices (durable reconnect)

1. **Gormes endpoints + capability advertisement** — `gormes-agent` commit
   `5e6ef089f`, **merged to `development`** (`41009dcbe`).
   `/v1/navivox/device-credentials` issue/list + `/revoke`
   (interim `device_bearer`, transport-gated, secrets hashed/never logged,
   idempotent revoke); `capability.DurableReconnect` advertises support on safe
   transport, fail-closed otherwise.
2. **Client parse + readiness** — already present in `navivox-app`; verified
   (`reconnect_readiness_test.dart`).
3. **Readiness surfaced in gateway-status UI** — `navivox-app` `main`
   (`dd1af32`). Manage-gateway sheet shows reconnect readiness for the active
   gateway.
4. **Client issuance method** — `navivox-app` `main` (`f1d386b`).
   `NavivoxGatewayClient.issueDeviceCredential`.
5. **Issuance + store seam + connect wiring** — `navivox-app` `main`
   (`d3cb4f8`). `DurableReconnectIssuanceCoordinator` issues → stores →
   flips readiness to `saved` after authenticated connect, one bounded retry,
   failures stay session-only without undoing the connection;
   `DurableCredentialStore.saveCredential` write seam with a no-op `Empty`
   default (production never writes a secret insecurely).

## Honest caveat

Production persistence is a no-op until a real Android secure-storage
`DurableCredentialStore` is injected, so on a device today reconnect readiness
resolves to **session-only ("available, not saved")**, never falsely "saved".
The orchestration, retry, failure handling, and readiness logic are fully built
and proven against fakes.

## Remaining work — device-gated (BLOCKED)

Tracked in `TODO.md` under the durable-credential item:

- Real Android secure-storage `DurableCredentialStore` backing.
- ECDSA P-256 keystore keypair challenge (`device_key_challenge`) via the
  native MethodChannel.
- `device_bearer`-as-request-auth silent reconnect.
- Live end-to-end validation.

All require a responsive physical/emulated Android target, which this host does
not have (`adb devices` empty; Flutter sees only Linux/Chrome).

## Other open work

The remaining `[PLANNED]`/`[BLOCKED]` `TODO.md` items still wait on external
dependencies:

- **Approval response protocol** — needs Gormes to advertise a stable
  approve/deny endpoint (Gormes + client work; **not** device-gated, so it is
  the most actionable next goal if a non-blocked item is wanted).
- **Composer attachment upload / media picker** — needs Gormes to advertise
  `/v1/navivox/uploads`.
- **Android pairing-handoff + continuous-voice live smoke** — needs a
  responsive Android target.

## Loose ends

- None outstanding for the non-device-gated work: Gormes Slice 1 is merged to
  `development` (`41009dcbe`) and the Navivox slices are on `main`.

## Acceptance audit

Durable reconnect is complete for every requirement reachable without an
Android device; the device-gated remainder is honestly blocked and recorded in
`TODO.md`. The next goal should target the approval-response protocol (the only
non-device-gated open item) or wait for a responsive Android target.
