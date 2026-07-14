# Lexical Affinity Verifier Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Doubtful Needle matches flow straight to Hermes via lexical anchor evidence, per `docs/superpowers/specs/2026-07-14-affinity-preroute-design.md`.

**Architecture:** Pure static `VoiceCommandAffinity` service + one guard line in `VoiceCommandRouter.route` after validation. Spike-bank fixture recalibrated (case 11 flips to null, intentionally).

**Tech Stack:** pure Dart; existing test harnesses.

## Global Constraints

- Branch `feat/affinity-preroute` from current `main`; stage only named files; never bare `git add -A`; user's pre-existing dirty files untouched.
- Zero added latency/model calls; no transcript logging; analyze clean + format per commit; TDD.

---

### Task 1: Affinity service + router guard + fixture recalibration

**Files:**
- Create: `lib/features/voice_commands/services/voice_command_affinity.dart`
- Modify: `lib/features/voice_commands/services/voice_command_router.dart` (guard after validate)
- Modify: `test/features/voice_commands/voice_command_router_test.dart` (affinity guard test, Step 3)
- Modify: `test/features/voice_commands/spike_bank_regression_test.dart` (case 11 expectation + comment)
- Test: `test/features/voice_commands/voice_command_affinity_test.dart` (new)

**Interfaces:**
- Consumes: `VoiceCommandId` (Task 2 of the router plan), `VoiceRouteResult`, `VoiceCommandValidator` normalization conventions.
- Produces: `abstract final class VoiceCommandAffinity { static bool trusts(String transcript, VoiceCommandId command); }` with the exact anchor table from the spec (copy it verbatim; multiword anchors matched by phrase containment on the normalized transcript, single-word anchors by word-boundary containment — split on spaces and check membership OR use RegExp `\b`). Normalization identical to the validator: trim, lowercase, collapse whitespace.

- [ ] **Step 1: Write the failing affinity unit test** — table-driven, one hit + one miss per command (18 cases). Hits drawn from the spike bank's correct transcripts (e.g. stopVoiceRun × 'cancel the recording'); misses drawn from the wrong-tool cases (switchSession × 'take me back to the chat' ⇒ false; toggleContinuousMode × 'start a new conversation' ⇒ false; setTtsVoice × 'speak faster please' ⇒ false) plus synthetic misses for the rest. Full test code written out; run: FAIL (file missing).
- [ ] **Step 2: Implement `VoiceCommandAffinity`** per Produces. Run affinity test: PASS.
- [ ] **Step 3: Router guard (red first)** — add to `voice_command_router_test.dart`: a scripted engine returning `switch_session{"session_name": "groceries"}` for transcript 'take me back to the chat' with context sessionTitles ['groceries'] ⇒ route returns null (validation would pass — 'groceries' resolves — but affinity must reject). Run: FAIL. Then add the guard in `route`: after `VoiceCommandValidator.validate(...)` returns non-null `result`, `if (!VoiceCommandAffinity.trusts(trimmed, result.command)) return null;`. Run: PASS.
- [ ] **Step 4: Recalibrate the fixture** — in `spike_bank_regression_test.dart`, change case 11 ('start a new conversation') expected outcome from toggleContinuousMode/confirm to null, with a comment: "affinity pre-route catches the recorded wrong-tool before the chip (2026-07-14)". Run the fixture: all 22 must pass (16 correct matches must survive affinity — if any fails, adjust the ANCHOR TABLE, never the correct-case expectations, and mirror the change into the spec's table in the same commit).
- [ ] **Step 5: Gate + commit** — `flutter test test/features/voice_commands && flutter analyze lib/features/voice_commands` clean; format. Commit all four files: `feat(voice-commands): lexical affinity pre-route guard`.

---

### Task 2: Docs + full gate

**Files:**
- Modify: `docs/superpowers/specs/2026-07-13-needle-router-design.md` (deviations: add "Hybrid pre-routing shipped 2026-07-14 via lexical anchor affinity — engine confidence remains unusable (pinned 1.0); doubtful matches flow to Hermes with no UI")
- Modify: `docs/superpowers/specs/2026-07-13-needle-spike-findings.md` (§4 verdict table: Hybrid pre-router row → "Shipped 2026-07-14 via lexical affinity (see affinity-preroute design)")

- [ ] **Step 1:** doc edits. **Step 2:** full gate: `flutter test` (report count) + `flutter analyze` + `flutter build apk --release` builds with `.so` present (grep = 1). **Step 3:** Commit both docs: `docs(voice-commands): hybrid pre-routing shipped via affinity`. **Step 4:** report; merge is the user's call; optional user ears/eyes check: speaking "take me back to the chat" should now land in the composer/Hermes with no chip.
