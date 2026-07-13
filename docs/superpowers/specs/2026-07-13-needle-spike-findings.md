# Needle Spike — Findings

**Spec:** docs/superpowers/specs/2026-07-13-needle-spike-design.md
**Device:** Samsung Galaxy S24 Ultra (SM-S928B), Android 16, 4 KB pages, CPU-only
(no Cactus Pro/NPU key), battery ~15% on charger, power-saving disabled for the run
**Engine:** cactus-compute/cactus@49e12567 · needle-cq4 (16,185,061 B zip)
**Method:** automated Maestro flow (`scripts/spike/maestro_eval.yaml`) tapping all 20
canned transcripts; results screenshotted and scored against each chip's expected tool.

## 1. Does it run?

**Yes — after three integration fixes** (each now committed with regression coverage):

- Dart isolate closures capturing engine state made every `Isolate.run` spawn fail
  (`object is unsendable`); fixed with static spawn helpers.
- The upstream Android build hides the C API behind `-Wl,--exclude-libs,ALL`, so
  `cactus_init` wasn't exported and FFI lookup failed on device; fixed by patching the
  flag out in `scripts/spike/build_cactus_engine.sh` with a post-build symbol check.
- Release builds don't render a semantics tree, blinding UI automation; fixed with a
  `NEEDLE_SPIKE`-gated `ensureSemantics()` in `main()`.
- Telemetry kill switch active: `CACTUS_NO_CLOUD_TELE=1` set via libc `setenv` before
  `cactus_init` (verified against engine source: init.cpp:21–25, telemetry_impl.cpp:1300).
  Runtime traffic capture was NOT performed during this run (Wi-Fi stayed on); an
  airplane-mode spot-check remains open.
- Coexistence with `flutter_onnxruntime`/pocket_speech: no build or load conflicts; both
  native runtimes ship in one APK and the app runs. Simultaneous TTS-while-inferring was
  not exercised.

## 2. Accuracy (20 canned transcripts, typed via automation)

| Verdict | Count |
|---|---|
| Correct | 16 |
| Wrong tool | 3 |
| Wrong args | 1 |
| No call | 0 |

**80% fully correct; 85% correct tool.** Failures, verbatim:

- "take me back to the chat" → `switch_session {session_name: back}` (expected
  `navigate_to_screen`) — wrong tool.
- "start a new conversation" → `toggle_continuous_mode {enabled: true}` (expected
  `new_session`) — wrong tool; its paraphrase "give me a fresh session" was correct,
  suggesting brittleness to phrasing rather than a category gap.
- "speak faster please" → `set_tts_voice {voice: faster}` (expected `set_speech_rate`)
  — wrong tool + nonsense arg; the harder paraphrase "slow the reading speed down to
  half" scored perfectly (`{rate: 0.5}`).
- "open the settings screen" → right tool, but arg `screen: "settings screen"` instead
  of enum value `"settings"` — the model echoes utterance words rather than snapping to
  the schema enum.

Notable wins: negation ("disable hands free mode" → `enabled: false`), free-text
extraction ("tell the agent I will be ten minutes late" → exact text), numeric
normalization ("half" → `0.5`), and every no-arg tool call was argument-clean.
`confidence` reported 1.000 on all 20 runs — useless as a routing signal at this size.

Mic-spoken utterances: **not evaluated** (automation can't speak; the manual 5-utterance
pass remains open for a later ad-hoc session).

## 3. Size & speed

- APK delta (release, arm64): baseline 116,502,480 B → gated eval build ~121.9 MB
  (**≈ +5.4 MB**: ~4 MB stripped engine .so + spike Dart + exported symbols).
- Note: `libcactus_engine.so` ships in the APK regardless of NEEDLE_SPIKE once built
  locally (Gradle packages jniLibs unconditionally); flag-off APKs on a machine with the
  .so present are NOT byte-identical to baseline.
- Model on disk: 16.2 MB zip download, extracted bundle of similar order — vs the 500 MB
  Kokoro TTS bundle the app already manages.
- Latency over the 20 runs (wall = tap→parsed result in Dart): **p50 662 ms, p95 670 ms,
  range 641–675 ms**; engine-reported total ≈ wall −3 ms; ttft ≈ 627–651 ms. Remarkably
  flat variance. CPU-only; NPU (paid tier) untested. Battery was at ~15% (slow charging),
  so mild thermal/battery throttling can't be excluded — treat numbers as conservative.
- First-run model load: not separately instrumented; the load+first-inference completed
  well inside the flow's scroll window (≲30 s, one-time per process).

## 4. Verdict (augment-only; Hermes remains the intelligence source)

| Role | Go/No-go | Why |
|---|---|---|
| Local voice-command router | **Go, with guardrails** | 85% tool accuracy and ~660 ms wall latency are workable for a whitelisted command set, but 15% wrong-tool means confirmations (or an allowlist of reversible actions) are mandatory; `confidence` can't gate — it's always 1.0. |
| Hybrid pre-router | **Not yet** | Pre-routing needs a reliable "don't know → hand off" signal; Needle confidently mis-tools paraphrases, so it would swallow utterances Hermes should get. Revisit if a usable confidence/verifier emerges. |
| Offline fallback | **Go (narrow)** | For a degraded offline command set (start/stop/status/settings), observed accuracy on direct phrasings was 100%; failures clustered in paraphrases. |

**Recommendation:** proceed to a real integration design for the **local voice-command
router** role, scoped to reversible actions with visible confirmation, arg normalization
(snap to enums client-side), and per-tool paraphrase testing. Fix the three wrong-tool
phrasings via tool descriptions/fine-tuning before shipping anything. Keep the augment-only
constraint: Needle never replaces the Hermes path.

**Open items:** mic-spoken pass (5+ utterances), airplane-mode telemetry spot-check,
TTS-coexistence-under-load check, and a decision on upstreaming the symbol-export patch.
