/// Choices for responding to a Hermes run approval request
/// (`POST /v1/runs/{run_id}/approval`), matching the options documented in
/// docs/product/hermes-agent-interface-plan.md. `name` is sent verbatim as
/// the `decision` field.
enum HermesApprovalDecision { once, session, always, deny }
