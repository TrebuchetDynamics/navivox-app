# Hermes platform smoke checklist

Use this checklist while moving Navivox from the legacy Gormes UI toward the
native Hermes Agent UI. It separates build-only gates from live-device gates so
we do not claim mobile/desktop parity from widget tests alone.

## Build gates

Run from the repo root:

```bash
flutter analyze
flutter test --concurrency=1
flutter build web --release -t lib/main_e2e.dart
flutter build apk --debug
flutter build linux
```

Current local receipts (2026-07-01):

- `flutter analyze` — pass.
- `flutter test --concurrency=1` — pass, 986 tests.
- `flutter build web --release -t lib/main_e2e.dart` — pass.
- `flutter build apk --debug` — pass, artifact at `build/app/outputs/flutter-apk/app-debug.apk`.
- `flutter build linux` — pass, artifact at
  `build/linux/x64/release/bundle/navivox`. This container has no passwordless
  `sudo`, so `libsecret-1-dev`/`libgcrypt20-dev`/`libgpg-error-dev` (required
  by `flutter_secure_storage_linux`'s `pkg_check_modules(... libsecret-1 ...)`)
  can't be `apt-get install`ed system-wide. Root-less recipe used instead:
  1. `apt-get download libsecret-1-dev libgcrypt20-dev libgpg-error-dev`
     (download only, no root needed) and `dpkg -x <pkg>.deb <prefix>` each
     into a local prefix directory.
  2. Copy the `.pc` files from `<prefix>/usr/lib/x86_64-linux-gnu/pkgconfig/`
     into a separate directory, rewriting `prefix=/usr` to
     `prefix=<prefix>/usr` in each (the extracted `.pc` files still point at
     the system `/usr` by default).
  3. Fix the dev package's `libsecret-1.so -> libsecret-1.so.0` symlink,
     which is dangling inside the extracted prefix (the versioned `.so.0` is
     only installed system-wide by the already-present runtime package,
     `libsecret-1-0`) — repoint it at the real system file:
     `ln -sf /usr/lib/x86_64-linux-gnu/libsecret-1.so.0 <prefix>/usr/lib/x86_64-linux-gnu/libsecret-1.so`.
  4. `rm -rf build/linux` (force a clean CMake configure — a cached
     `CMakeCache.txt` from an earlier failed attempt will otherwise keep a
     stale `pkgcfg_lib_LIBSECRET_secret-1-NOTFOUND` `find_library` result
     even after the symlink is fixed) and rerun `flutter build linux` with
     `PKG_CONFIG_PATH` pointing at the rewritten `.pc` directory and `CPATH`
     pointing at `<prefix>/usr/include`.
  The resulting binary links the real system `libsecret-1.so.0` at runtime
  (confirmed via `ldd`) — the local prefix is a build-time-only stand-in for
  the missing dev headers/symlink, not something the shipped binary depends
  on. This recipe is only needed in root-less containers; CI/normal dev
  machines should just `apt-get install libsecret-1-dev`.
- `flutter build windows` — blocked here because Flutter only supports this
  command on Windows hosts.
- `flutter build ios` — blocked here because this Linux Flutter toolchain does
  not expose the iOS build subcommand; validate on macOS/Xcode.

Windows and iOS platform folders are present. The iOS `Info.plist` includes
microphone and speech-recognition usage descriptions for the Hermes
voice-to-text path. Windows and iOS builds must run on their host platforms/CI
runners; they are not validated from this Linux container.

Host-runner CI for Ubuntu/Windows/macOS is still pending; validate these gates
manually until a workflow can be pushed with GitHub `workflow` permission.

## Browser e2e Hermes smoke

```bash
flutter build web --release -t lib/main_e2e.dart
node serve_web.mjs &
npx playwright test --config=playwright.config.mjs playwright/tests/regression/hermes-smoke.spec.mjs --reporter=list
```

The e2e server provides a local Hermes HTTP/SSE fake so the browser test uses
real `HermesApiChannel` web transport for health, capabilities, sessions, runs,
run events, approvals, tool progress, and stop/approval endpoints.

Current receipt (2026-07-01): 2 Chromium tests pass, covering disconnected
setup hints plus connected text, new-session, voice-transcript, approval, stop,
and tool-progress UI.

## Live Hermes Agent smoke (still required)

When a real Hermes Agent API server is available:

1. Start Hermes Agent API server on `127.0.0.1:8642` with test credentials.
2. Open Navivox `/hermes` on web/desktop or Android.
3. Connect using the platform-appropriate URL:
   - desktop/Linux/Windows/iOS simulator: `http://127.0.0.1:8642`
   - Android emulator: `http://10.0.2.2:8642`
   - physical device: LAN/VPN/Tailscale URL
4. Verify: session list/create, typed text turn, streamed assistant response,
   tool progress card, approval prompt + response, stop, reconnect from saved
   endpoint, push-to-talk voice transcript, and continuous voice loop.

## Android live smoke (still required)

A debug APK builds locally, but no responsive Android device/emulator was
available in this environment. On a device runner:

```bash
flutter install -d <device-id>
flutter run -d <device-id>
```

Then run the live Hermes Agent smoke above, including microphone permission,
STT capture, TTS playback, and continuous re-arm behavior.
