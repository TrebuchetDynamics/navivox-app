# Navivox Context

Navivox is the Flutter companion for Hermes Agent. Product language, routes, tests, and docs should describe Hermes endpoints, Hermes sessions, Hermes runs, local device speech-to-text, approvals, tool progress, and local settings.

## Active routes

- `/hermes` — Hermes Agent connection, sessions, chat, runs, voice transcript submission, approvals, stop controls, and diagnostics.
- `/settings` — local voice preferences for this install.

## Endpoint language

Use **Hermes endpoint** or **Hermes Agent API server** for the trusted server. Use **session** for the durable conversation lane. Use **run** for streamed work with events, approvals, and stop controls.

## Voice language

Use **voice input** for on-device speech-to-text that fills the composer for operator review. Use **continuous voice** for the opt-in hands-free extension that submits transcripts, speaks completed Hermes replies, and re-arms capture. Use **Pocket Speech model** for the selected Kitten or Kokoro engine and **voice pack** for its downloaded model and voices resources.

## Transcript language

Use **rich transcript** for selectable GitHub-flavored Markdown in Hermes-authored replies, including code-copy controls. User messages remain plain text, external links use an allowlist, and remote transcript media stays deferred.

## Security posture

API keys are secrets. Endpoint URLs are non-secret metadata but still operator-controlled. Prefer loopback, LAN, VPN, Tailscale, or TLS URLs. Do not log API keys or pairing secrets.
