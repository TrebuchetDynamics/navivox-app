# Hermes Desktop Reference For Gormes-First Navivox

Status: accepted reference direction
Reference: `fathah/hermes-desktop` cloned at `/tmp/hermes-desktop` during the 2026-06-03 planning session

## Decision

Navivox stays Gormes-first. Its main product promise remains the Flutter operator app for trusted local or self-hosted Gormes gateways and Gormes Profile contacts.

Hermes Desktop is useful reference material for app shape, not a near-term runtime target. Navivox may borrow product patterns from Hermes Desktop while preserving the Gormes `/v1/navivox/*` HTTP/WebSocket boundary, Pairing handoff, Profile contact model, Run record evidence model, config-admin safety model, and Goncho memory console.

## Reference Behaviors Worth Learning From

Hermes Desktop is an Electron/React shell for Hermes Agent. The patterns worth studying are:

- chat as the primary workspace;
- profile switching and profile management close to chat;
- sessions, models, providers, memory, tools, skills, schedules, gateway, and settings as operator surfaces;
- local or remote gateway setup made understandable for non-terminal operation;
- streaming assistant work rendered as product UI with tool progress and usage evidence;
- simple navigation that keeps day-to-day chat, memory, tools, and gateway status nearby.

These are product and UX lessons. They do not imply that Navivox should speak Hermes Agent's `/health` or `/v1/chat/completions` protocol in the main plan.

## Navivox Shape

Near-term Navivox route vocabulary should continue to respect Gormes domain terms:

| Hermes Desktop surface | Gormes-first Navivox interpretation |
| --- | --- |
| Chat | existing Profile contact Transcript surface |
| Sessions | Gormes `/v1/navivox/sessions` and Run record evidence, once UI wiring is complete |
| Profiles | existing Profile contacts and Profile seed flows, not generic Hermes profiles |
| Models / Providers | Gormes config-admin model/provider settings where advertised |
| Memory | Goncho memory overview/search/detail/action APIs through Gormes |
| Tools / Skills | Gormes tool activity, approvals, and capability-gated operator surfaces |
| Gateway | Gormes Navivox gateway management, Pairing handoff, durable reconnect readiness |
| Settings | local app settings plus Gormes capability/config affordances |

## Boundary Rules

- Gormes remains the runtime and gateway family for the current Navivox plan.
- Hermes Desktop may inform navigation, visual hierarchy, and operator surface prioritization.
- Do not add a Hermes Agent wire-protocol client unless a future ADR explicitly changes the runtime scope.
- Do not rename Gormes-specific domain concepts to Hermes concepts when the data still comes from Gormes.
- Keep `Profile contact`, `Pairing handoff`, `Run record`, `Voice readiness`, `Gateway identity`, and Gormes config-admin language stable.

## Hermes Protocol Spikes

Hermes protocol experiments should stay out of production Navivox code unless a future ADR explicitly reopens Hermes runtime support. Prefer preserving lessons in docs and tests for Gormes-facing adapters rather than keeping unused Hermes wire clients in `lib/`.

The 2026-06-03 Hermes runtime spike was removed from production code after the Gormes-first decision was accepted. Future spikes should be clearly marked as exploratory and deleted or quarantined when their learning is captured.

## Next Gormes-First Slices Inspired By Hermes Desktop

1. Improve the Profile contact chat surface using Hermes Desktop's chat-first ergonomics.
2. Wire Gormes sessions and Run records into a discoverable operator evidence surface.
3. Make profile switching/profile seed flows feel closer to Hermes Desktop's profile management while preserving Gormes Profile contact semantics.
4. Prioritize Models/Providers through Gormes config-admin rather than a separate Hermes settings model.
5. Keep the Gateway surface focused on Pairing handoff, Gateway identity, durable reconnect readiness, and safe exposure status.
