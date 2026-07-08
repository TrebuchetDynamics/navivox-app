# ADR 0005: Gate Hermes surfaces with the capabilities document

Status: accepted
Date: 2026-07-07

## Context

Hermes Agent exposes a capabilities document and optional endpoints. The README lists optional catalog, session, chat stream, run, approval, and stop endpoints. The channel probes capabilities on connect and conditionally loads detailed health, models, skills, toolsets, jobs, sessions, and mutable session features.

## Decision

Use Hermes Agent capabilities as the source of truth for optional client behavior. The app may optimistically connect to required basics, but optional surfaces must be guarded by advertised endpoints or transport policy.

## Consequences

- UI and channel behavior degrade when an endpoint is not advertised instead of assuming every Hermes Agent version supports every surface.
- Optional catalog/health/job failures remain best-effort diagnostics, not connection blockers.
- New Hermes endpoints should be wired through capabilities and policy checks before being surfaced in UI.

## Edge cases

- Missing optional endpoints should hide or disable only the dependent surface.
- Optional catalog, health-detail, or jobs probes may fail without disconnecting the user.
- A connected server with no supported chat transport must block sending turns with a clear error.

## Evidence

- `README.md:9-24`
- `lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart:27-53`
- `lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart:118-152`
- `lib/core/hermes/channel/api_channel/hermes_api_channel_messaging.dart:24-30`
- `lib/core/hermes/client/hermes_api_client.dart:154-214`
