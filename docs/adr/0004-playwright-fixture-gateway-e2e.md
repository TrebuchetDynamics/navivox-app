# Playwright fixture gateway E2E protects connect-and-talk

Status: preserved legacy Gormes browser-evidence decision plus current Hermes
extension. Current Playwright coverage also includes deterministic fake Hermes
HTTP/SSE browser smoke and env-gated live/provider Hermes specs; browser E2E
remains scoped evidence and is not a replacement for readiness-audit blockers.

Navivox will keep broad mock-channel Playwright tests for fast UI coverage, but the browser E2E gate must include at least one fixture-gateway path that enters setup fields, proves health/status/stream behavior, sends a real composer turn, and observes gateway-driven assistant output. Mock-only E2E can stay green while the pairing, browser input, HTTP/WebSocket, or first-turn contract is broken, so fixture-gateway coverage is the durable boundary for the connect-and-talk promise.

## Considered Options

- Keep Playwright entirely mock-backed: rejected because it proves seeded UI rendering but can bypass setup, transport, and composer submission.
- Rely only on Flutter widget E2E tests: rejected because they do not exercise the built web app through browser semantics and production routing.
- Add a full real Gormes dependency to browser E2E: rejected for the required gate because it would make local/CI validation depend on host setup, secrets, and runtime services.
