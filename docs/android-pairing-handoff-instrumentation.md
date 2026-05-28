# Optional Android Pairing Handoff Instrumentation Smoke

This smoke is optional until CI has a reliable Android emulator or physical device. It exercises the Flutter setup import seam with a sentinel pairing token and asserts the token is not rendered in normal visible setup copy.

Run with an attached Android target:

```sh
flutter test integration_test/android_pairing_handoff_smoke_test.dart -d <android-device-id>
```

The test uses the sentinel token `ci-secret-token-do-not-render`. If a failure screenshot or log shows that value in visible UI, treat it as a token leak.

This does not replace manual OS intent checks. For real Android `ACTION_VIEW` and `ACTION_SEND` commands, see `docs/android-pairing-handoff-smoke.md`.
