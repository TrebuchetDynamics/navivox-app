# Durable Navivox connection credentials

Navivox will treat Pairing handoff tokens as short-lived bootstrap credentials, not as persisted connection secrets. Durable Android reconnect will use a Gormes-issued, revocable device credential bound to the authenticated Gateway identity and Navivox install/device identity, stored only in platform secure storage; non-secret gateway metadata may be stored separately in shared preferences. Flutter web will not get silent durable reconnect initially, and reconnect must prove the same Gateway identity before updating local metadata.

## Considered Options

- Persist Pairing handoff tokens: rejected because bootstrap tokens are meant for first-run transfer and are too easy to leak through shared text, screenshots, routes, or logs.
- Store bearer secrets in shared preferences or browser storage: rejected because those stores are not an acceptable secret boundary for durable gateway access.
- Require a new Pairing handoff after every Android restart: rejected because it harms the connect-and-talk loop when platform secure storage can protect a device credential.

## Consequences

Gormes needs a minimal authenticated device credential issue/list/revoke API, and revocation must block future auth immediately. Navivox `forget gateway` should attempt remote revoke but always remove local credential and metadata, reporting remote revocation as unconfirmed if Gormes is unreachable.
