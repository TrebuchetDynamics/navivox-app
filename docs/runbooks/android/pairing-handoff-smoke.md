# Android Pairing Handoff Smoke

Manual smoke for the Android platform seam. Use non-production tokens only.

## Direct app-open

```sh
adb shell am start \
  -a android.intent.action.VIEW \
  -d 'navivox://connect?base_url=http%3A%2F%2F127.0.0.1%3A8765&token=smoke-token'
```

Expected: Navivox opens setup with the pairing fields imported as a direct app-open source. If no gateway is active, Flutter policy may auto-connect. If a gateway is active, confirmation is required before probing or switching.

## Shared text

```sh
adb shell am start \
  -a android.intent.action.SEND \
  -t 'text/plain' \
  --es android.intent.extra.TEXT 'navivox://connect?base_url=http%3A%2F%2F127.0.0.1%3A8765&token=smoke-token'
```

Expected: Navivox opens setup with the pairing fields imported as a shared-text source. It must fill fields and wait for operator action; shared text must not auto-connect.

## Token handling

Expected: UI and diagnostics must not display the token value. If the connection fails, recovery copy should describe the pairing link/source without echoing secrets.
