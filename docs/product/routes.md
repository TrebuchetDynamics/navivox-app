# Routes

Hermes Wing uses one adaptive route tree. Android currently keeps Chat and Settings in the compact bottom bar and places working administrative slices in More; desktop layouts map the same routes to a navigation rail. Routes are added with working vertical slices, so approved entries may remain planned until their capability lands.

| Route | Android placement | Purpose | State |
| --- | --- | --- | --- |
| `/hermes` | Chat | Connection, sessions, runs, voice, approvals, and diagnostics. | implemented |
| `/discover` | Discover | Skills and MCP discovery. | planned |
| `/office` | Office | Adaptive Hermes Office. | planned |
| `/tasks` | More | Gateway-scoped, read-only scheduled-job inventory; schedule mutation and Kanban remain contract-gated. | partial |
| `/agents` | More | Profiles, persona, and profile administration. | implemented |
| `/enroll` | (deep link) | One-time pairing-code enrollment, outside the shell. | implemented |
| `/providers` | More | Providers, models, and task-model overrides. | implemented |
| `/tools` | More | Gateway-scoped searchable installed-skill metadata and enabled toolsets; mutation and MCP administration remain contract-gated. | partial |
| `/memory` | More | Memory entries, profile, capacity, and providers. | planned |
| `/gateway` | More | Gateway-selected bounded health status; lifecycle, logs, and messaging-platform administration remain contract-gated. | partial |
| `/settings` | More | Local application and installation preferences. | implemented |

Profile switching and session history remain directly reachable from Chat. More is an action sheet, not a route.
