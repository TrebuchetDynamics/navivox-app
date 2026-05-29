# Optional Android Durable Keystore Smoke

This smoke is optional until CI has a reliable Android target. It verifies only the native Android keystore boundary for future durable reconnect credentials; it does not enable reconnect and does not call any Gormes credential issuance endpoint.

Run Dart contract tests on any host:

```sh
flutter test test/core/session/durable_credential_key_store_test.dart
```

Run JVM helper tests on any host:

```sh
cd android
./gradlew :app:testDebugUnitTest --tests com.trebuchetdynamics.navivox.DurableKeySignatureEncodingTest
```

Run the on-device integration smoke only with a responsive Android target:

```sh
flutter test integration_test/durable_key_store_android_smoke_test.dart -d <android-device-id>
```

The integration smoke exercises `com.trebuchetdynamics.navivox/durable_keys` through the native channel boundary and confirms:

1. `isAvailable` is true on supported Android.
2. ES256 key creation returns a public JWK only: `kty`, `crv`, `x`, `y`, `alg`, optional `kid`; no private `d` field.
3. Signing canonical bytes returns a 64-byte JOSE raw `r || s` signature.
4. Deleting the key twice succeeds.
5. Aliases outside the `navivox_durable_` namespace are rejected.

Do not treat this smoke as durable reconnect validation. Reconnect remains disabled until credential issuance, secure storage metadata, Gateway identity proof, and revocation flows are implemented and validated.
