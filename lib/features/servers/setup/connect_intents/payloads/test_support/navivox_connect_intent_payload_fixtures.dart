import '../contracts/navivox_platform_connect_intent_payload.dart';

const navivoxRegressionConnectIntentPayload =
    'https://gateway.example/connect?token=nvbx_token';

Map<String, Object?> navivoxPlatformConnectIntentPayloadFixture({
  Object? payload = navivoxRegressionConnectIntentPayload,
  Object? source = sharedTextPairingHandoffPlatformSource,
}) {
  return {'payload': payload, 'source': source};
}
