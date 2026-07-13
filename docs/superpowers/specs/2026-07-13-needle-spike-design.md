# Needle On-Device Tool-Calling Spike — Design

**Date:** 2026-07-13
**Status:** Approved (spike; findings decide whether a real integration design follows)
**Branch:** `spike/needle` (never merged as-is; only findings return)

## Background

[Needle](https://huggingface.co/Cactus-Compute/needle) is a 26M-parameter, MIT-licensed
function-calling model from Cactus Compute (Simple Attention Network: encoder-decoder,
attention-only, INT4 QAT). It does one thing: map natural-language requests to structured
tool calls. It runs on the Cactus engine (v2.x), which has a Flutter binding.

Navivox is remote-only for intelligence today: OS STT transcript → Hermes endpoint (SSE).
The app already runs on-device ONNX inference for TTS (`pocket_speech`), with an
established model-download pattern (SHA-256 verification, size caps, atomic replace).

## Guiding constraint (hard scope boundary)

**Needle augments Hermes; it never replaces it.** All candidate roles keep the Hermes
endpoint as the source of intelligence. Needle may only short-circuit or pre-route
simple, local, structured commands. Any design derived from this spike that removes or
degrades the Hermes path is out of scope.

## Goal & questions to answer

A time-boxed, rip-out-able experiment answering, in order:

1. **Does it run?** Needle loads and infers inside Navivox on Android (alpha target) via
   the Cactus Flutter binding, coexisting with `flutter_onnxruntime` (pocket_speech TTS).
2. **Is it accurate?** Fraction of realistic voice commands mapped to the right tool with
   the right arguments, against ~10 mock Navivox tools and a 20-transcript test bank.
3. **Is it fast/small enough?** End-to-end latency (transcript → tool call), APK size
   delta, model download size.
4. **Verdict:** recommend one integration role — local command router, hybrid pre-router,
   offline fallback — or "not yet, revisit when X".

## Decisions made during brainstorming

| Decision | Choice |
|---|---|
| Role of Needle | Exploratory spike first; role decided by findings |
| Where the spike lives | In-repo behind a debug flag (proves onnxruntime coexistence) |
| Spike depth | Debug screen + mic button (reuses existing `SpeechRecognizer`; does NOT touch the Hermes voice-run path) |
| Runtime path | `cactus` as a git dependency pinned to a v2.x commit of `cactus-compute/cactus` (pub.dev 1.3.0 predates Needle; git-dep mirrors the existing `pocket_speech` pattern) |
| Relationship to Hermes | Augment only — never replace (user directive) |

## Architecture

- **Dependency:** `cactus` git dependency pinned to a specific v2.x commit in
  `pubspec.yaml`, alongside the existing `pocket_speech` git dep.
- **Gating:** all spike code lives under `lib/features/needle_spike/`; the debug route is
  registered only when built with `--dart-define=NEEDLE_SPIKE=true`. Builds without the
  flag ship no reachable spike UI. (The native Cactus lib lands in the APK once the
  dependency exists — measuring that delta is part of the spike.)
- **Isolation:** no imports from `needle_spike` into any other feature. The spike imports
  shared services (`SpeechRecognizer`, download plumbing) but nothing imports it.

## Components

### `NeedleToolCatalog`
~10 hardcoded `CactusTool` definitions mirroring plausible Navivox actions:
`navigate_to_screen`, `start_voice_run`, `stop_voice_run`, `toggle_continuous_mode`,
`send_message`, `new_session`, `switch_session`, `set_tts_voice`, `set_speech_rate`,
`show_status`. Handlers are mocks — they return a canned "would have executed X(args)"
string and never touch real app state.

### `NeedleSpikeService`
Wraps model download (reusing the SHA-256-verified pattern from
`pocket_speech_asset_download_service_io.dart`), engine init, and
`parseTranscript(String) → NeedleResult { toolCall?, latencyMs, raw }`.
Exposed via a Riverpod provider, consistent with existing feature wiring.

### `NeedleSpikeScreen`
Hidden debug screen containing:
- free-text input field;
- a bank of ~20 canned test transcripts (one tap to run);
- a mic button that reuses the existing `SpeechRecognizer` service directly —
  not `HermesVoiceInputController`, not the voice-run submission path;
- result panel: parsed tool call, arguments, latency;
- manual scorecard: correct / wrong tool / wrong args / no call (counts only).

## Data flow

Mic or typed text → transcript string → `NeedleSpikeService.parseTranscript` → Needle
inference (fully on-device) → displayed result + manually judged scorecard tick.
Nothing reaches the Hermes endpoint. No network traffic after the one-time model download.

## Error handling & security

- Model fails to download/load or binding is incompatible → screen shows the error
  verbatim; that outcome is itself finding #1.
- Per repo security policy: transcripts are displayed but **never logged or persisted**;
  the scorecard stores only counts, never utterances.
- Download failures follow the pocket_speech pattern: temp-file atomic replace, size cap,
  checksum verification.

## Testing

- Unit tests for `NeedleToolCatalog` (schema validity) and `NeedleSpikeService` result
  parsing (with the engine faked), mirroring existing controller test style.
- The accuracy evaluation itself is manual via the debug screen scorecard — the spike's
  product is the findings doc, not shippable code.

## Exit criteria & deliverable

The spike ends with `docs/superpowers/specs/2026-MM-DD-needle-spike-findings.md`
recording:

- load success/failure (with binding version details);
- accuracy on the 20-transcript bank (per-category: correct / wrong tool / wrong args /
  no call);
- p50/p95 latency on the test device;
- APK size delta and model download size;
- flutter_onnxruntime coexistence notes (build conflicts, runtime issues, memory);
- go/no-go recommendation per integration role, honoring the augment-only constraint.

## Pros & cons of Needle for Navivox (known pre-spike)

**Pros**
- MIT license, open weights.
- Tiny: ~20–30 MB on disk vs the 500 MB Kokoro TTS model the app already manages.
- Very fast claimed inference (~6,000 tok/s prefill / ~1,200 decode on Cactus runtime).
- Exactly matches Navivox's "voice command → structured action" shape.
- Fits the app's existing hybrid on-device/remote philosophy and download plumbing.
- Cactus Flutter SDK also offers on-device Whisper STT — possible future bonus.

**Cons / risks**
- Function-calling only — can never carry conversation (acceptable: augment-only).
- Brand-new model + v2 engine; Flutter binding maturity unproven (biggest risk; the
  spike's primary question).
- Adds a second native inference runtime beside onnxruntime (APK size, build complexity).
- pub.dev package lags the engine; git dependency required for now.
- NPU acceleration is gated behind a paid Pro key (CPU-only for the spike).
- 26M params: argument extraction on messy real speech may be brittle.
- Unclear story for Navivox's secondary targets (web, Linux, iOS).
