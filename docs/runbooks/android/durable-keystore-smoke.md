# Android Durable Keystore Smoke (legacy)

Status: preserved legacy check. This runbook is **not** part of the active
pure-Hermes Navivox readiness gate.

The active Hermes app connects to Hermes Agent API endpoints and stores the
Hermes API key through secure storage. Real release readiness is tracked in
[Hermes companion readiness audit](../hermes-readiness-audit.md) and the active
Android closeout is [Android live microphone Hermes smoke](live-mic-smoke.md).

## Automated key readiness

Run on a connected Android device/emulator only when maintaining preserved
legacy durable-key code:

```bash
npm run android:durable-key-smoke
```

or target a specific device:

```bash
NAVIVOX_ANDROID_DEVICE_ID=<device-id> npm run android:durable-key-smoke
```

The smoke runs `integration_test/durable_key_store_android_smoke_test.dart` and
verifies:

- the native durable key MethodChannel is available;
- an ES256/P-256 keypair can be created under a `navivox_durable_*` alias;
- only public JWK fields are exported (`kty`, `crv`, `alg`, `x`, `y`), never
  private `d` material;
- payload signing returns a 64-byte ES256 signature;
- deleting the alias is safe and repeatable;
- unsafe non-durable aliases are rejected;
- the Dart `MethodChannelDurableCredentialKeyStore` adapter exercises the same
  create/sign/delete path.

This is legacy key storage readiness only. It does **not** prove active Hermes
chat, voice, provider, platform, or realtime/server-audio readiness, and it is
not a blocker for the pure-Hermes companion goal.

Before any active Hermes completion claim, run strict readiness audit instead:

```bash
NAVIVOX_FAIL_ON_BLOCKERS=1 npm run hermes:readiness-audit
```

If unrelated blockers remain, the expected result is exit 3 with
`Completion verdict: NOT COMPLETE`; do not promote this legacy key smoke,
passing tests, APK hashes, configured Hermes home, workflow YAML, or
dispatch-only output to whole-goal completion.
