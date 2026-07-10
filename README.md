# Navivox

Navivox is a Flutter companion for trusted local, VPN, or self-hosted Hermes Agent sessions.

## Runtime

The app targets the Hermes Agent API server, commonly on port `8642`:

- `GET /health`
- `GET /v1/capabilities`
- `GET /v1/models`
- `GET /v1/skills`
- `GET /v1/toolsets`
- `GET /api/sessions`
- `POST /api/sessions`
- `PATCH /api/sessions/{session_id}`
- `DELETE /api/sessions/{session_id}`
- `GET /api/sessions/{session_id}/messages`
- `POST /api/sessions/{session_id}/fork`
- `POST /api/sessions/{session_id}/chat/stream`
- `POST /v1/runs`
- `GET /v1/runs/{run_id}/events`
- `POST /v1/runs/{run_id}/approval`
- `POST /v1/runs/{run_id}/stop`

## Run

Navivox consumes the pinned `pocket_speech` package for optional offline speech
synthesis.

```bash
flutter pub get
flutter run -d <device-id>
```

Hermes endpoint hints:

- Desktop on same host: `http://127.0.0.1:8642`
- Android emulator to host: `http://10.0.2.2:8642`
- Physical Android on Tailscale/LAN/VPN: `http://<hermes-host>:8642`

When an API key is used with a non-loopback `http://` endpoint, Navivox asks
for explicit confirmation. Prefer HTTPS; use cleartext credentials only inside
a trusted VPN, Tailscale network, or isolated LAN.

Voice input uses on-device speech recognition and fills the composer for review
before sending. Foreground continuous voice is a separate opt-in mode. The loop
stops and discards late transcripts when disabled, backgrounded, disconnected,
or switched to another Hermes session. Say `navi stop`, `navi pause`,
`navi mute`, or `navi cancel` to pause without sending the command to Hermes.

Optional offline TTS is provided by Pocket Speech. Navivox can select Kitten
nano-int8 (about 26 MB) or Kokoro (about 365 MB including voices), then download
the selected voice pack from pinned release defaults. Release operators may
override the HTTPS URLs and SHA-256 digests:

```bash
flutter run \
  --dart-define=KITTEN_MODEL_URL=https://example/kitten/model.onnx \
  --dart-define=KITTEN_MODEL_SHA256=<64-hex-digest> \
  --dart-define=KITTEN_VOICES_JSON_URL=https://example/kitten/voices.json \
  --dart-define=KITTEN_VOICES_JSON_SHA256=<64-hex-digest> \
  --dart-define=KOKORO_MODEL_URL=https://example/kokoro/model.onnx \
  --dart-define=KOKORO_MODEL_SHA256=<64-hex-digest> \
  --dart-define=KOKORO_VOICES_JSON_URL=https://example/kokoro/voices.json \
  --dart-define=KOKORO_VOICES_JSON_SHA256=<64-hex-digest>
```

## Verify

```bash
flutter analyze
flutter test --concurrency=1
flutter build web --release -t lib/main_e2e.dart
npm run web:e2e
```
