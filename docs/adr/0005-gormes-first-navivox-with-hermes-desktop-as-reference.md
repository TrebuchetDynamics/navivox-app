# Keep Navivox Gormes-first and use Hermes Desktop as reference

Status: superseded by [ADR 0006 — Make Navivox Hermes Agent-first](0006-hermes-agent-first-runtime.md)

Navivox remains the Flutter operator app for trusted Gormes gateways, Profile contacts, Pairing handoff, Run records, config-admin, and Goncho memory. We will study `fathah/hermes-desktop` for app shape and UX patterns such as chat-first navigation, profiles, sessions, models/providers, memory, tools, gateway, and settings, but Hermes Agent's `/health` and `/v1/chat/completions` protocol is not the near-term runtime target. This avoids splitting the product around two incompatible gateway contracts while still letting Hermes Desktop inform a better Gormes operator experience.

## Considered Options

- Make Navivox Hermes-first now: rejected because current domain docs, setup flow, channel implementation, and validation all center Gormes `/v1/navivox/*` semantics.
- Add simultaneous first-class Hermes and Gormes gateway families now: rejected because it would force setup, persistence, credentials, stream parsing, and UI language decisions before the Gormes loop is finished.
- Keep Navivox Gormes-first while learning from Hermes Desktop: accepted because it preserves the main plan and still gives a strong reference for app shape.
