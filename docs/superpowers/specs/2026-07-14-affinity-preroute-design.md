# Lexical Affinity Verifier (Hybrid Pre-Routing) — Design

**Date:** 2026-07-14
**Status:** Approved
**Builds on:** docs/superpowers/specs/2026-07-13-needle-router-design.md; spike findings
verdict "Hybrid pre-router: not yet — needs a don't-know signal" (engine confidence is
pinned at 1.0 and unusable).

## Decision

The handoff signal is **lexical anchor evidence**, not model confidence: each command
declares normalized words/phrases that a transcript genuinely aimed at it would contain.
A validated Needle match whose transcript contains **no anchor of the proposed tool** is
doubted and flows **straight to Hermes** — no chip, no snackbar, indistinguishable from
a non-match. Zero added latency; no extra model calls.

## Component

`VoiceCommandAffinity` (new, `lib/features/voice_commands/services/`): static
`Map<VoiceCommandId, List<String>>` anchor table + `bool trusts(String transcript,
VoiceCommandId command)` using the validator's normalization (trim, lowercase,
whitespace-collapse; multiword anchors matched as phrase containment, single words as
word containment).

Anchor table (calibrated against the 20-case spike bank — all 16 correct matches keep
≥1 anchor; all 3 wrong-tool matches lose):

| Command | Anchors |
|---|---|
| navigateToScreen | open, go to, take me, settings, screen, chat |
| showStatus | status, connected, connection, online |
| stopVoiceRun | stop, cancel, pause, mute, quiet |
| startVoiceRun | listen, begin, start, voice, mic |
| toggleContinuousMode | continuous, hands free, hands-free, handsfree |
| newSession | new, fresh, conversation, session |
| switchSession | session, switch |
| setTtsVoice | voice |
| setSpeechRate | speed, rate, faster, slower, slow, quickly |

## Wiring

One chokepoint in `VoiceCommandRouter.route`: after `VoiceCommandValidator.validate`
returns non-null, `VoiceCommandAffinity.trusts(transcript, result.command)` must be
true, else return null. Applies uniformly to both tiers.

## Calibration & regression

The spike-bank fixture is the calibration set. Intentional expectation change: case 11
("start a new conversation" → recorded wrong-tool `toggle_continuous_mode{true}`)
flips from "confirm tier absorbs it" to **null (Hermes)** — the pre-router now catches
it before the chip. The 16 correct cases pin the table against overtightening.
Dedicated unit tests cover one hit and one miss per command.

## Docs

Router design doc: verdict for "Hybrid pre-router" → shipped via lexical affinity;
deviations note the confidence signal remains unusable and anchors are the substitute.
English-only anchors (consistent with the catalog); anchors live in code.

## Out of scope

Embedding/model verifiers, second-opinion sampling, threshold tuning, i18n anchors.
