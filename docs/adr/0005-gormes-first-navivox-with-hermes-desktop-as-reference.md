# Keep Navivox Gormes-first and use Hermes Desktop as reference

Status: superseded by [ADR 0006 — Make Navivox Hermes Agent-first](0006-hermes-agent-first-runtime.md) and [ADR 0007 — Build a native Hermes channel instead of a `HermesNavivoxChannel` adapter](0007-native-hermes-channel-not-navivox-channel-adapter.md)

Historical decision: Navivox remained the Flutter operator app for trusted Gormes gateways, Profile contacts, Pairing handoff, Run records, config-admin, and Goncho memory while studying `fathah/hermes-desktop` for app shape and UX patterns. Current mainline no longer follows this runtime direction: `/hermes` is the fresh-install Hermes Agent companion route and the preserved Gormes-first state lives on the `gormes` branch. Keep this ADR only as context for legacy Gormes paths and the later Hermes-first course correction.

## Considered Options

- Make Navivox Hermes-first now: rejected at the time because the then-current domain docs, setup flow, channel implementation, and validation all centered Gormes `/v1/navivox/*` semantics. ADR 0006 later reversed this product direction.
- Add simultaneous first-class Hermes and Gormes gateway families now: rejected at the time because it would have forced setup, persistence, credentials, stream parsing, and UI language decisions before the Gormes loop was finished.
- Keep Navivox Gormes-first while learning from Hermes Desktop: accepted at the time because it preserved the then-current plan and still gave a strong reference for app shape. This is historical context only on Hermes-first `main`.
