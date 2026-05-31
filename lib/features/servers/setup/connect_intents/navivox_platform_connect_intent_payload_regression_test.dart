import '../../models/connection_import.dart';
import '../test_support/regression_expect.dart';
import 'navivox_platform_connect_intent_payload.dart';

void main() {
  normalizesPlainStringPayloadAsManualSource();
  normalizesStructuredPayloadAndSourceToken();
  fallsBackToManualForUnknownPlatformSourceToken();
  rejectsNonStringPayloadFields();
}

void normalizesPlainStringPayloadAsManualSource() {
  final result = NavivoxPlatformConnectIntentPayload.from(
    ' https://gateway.example/connect?token=nvbx_token ',
  );

  regressionExpect(result != null, 'plain string payload should normalize');
  regressionExpect(
    result!.text == 'https://gateway.example/connect?token=nvbx_token',
    'plain string payload text should be trimmed',
  );
  regressionExpect(
    result.source == PairingHandoffSource.manual,
    'plain string payloads have no platform provenance metadata',
  );
}

void normalizesStructuredPayloadAndSourceToken() {
  final result = NavivoxPlatformConnectIntentPayload.from({
    'payload': ' https://gateway.example/connect?token=nvbx_token ',
    'source': directAppOpenPairingHandoffPlatformSource.toUpperCase(),
  });

  regressionExpect(result != null, 'structured payload should normalize');
  regressionExpect(
    result!.text == 'https://gateway.example/connect?token=nvbx_token',
    'structured payload text should be trimmed',
  );
  regressionExpect(
    result.source == PairingHandoffSource.directAppOpen,
    'platform source tokens should be trimmed and case-insensitive',
  );
}

void fallsBackToManualForUnknownPlatformSourceToken() {
  final result = NavivoxPlatformConnectIntentPayload.from({
    'payload': 'https://gateway.example/connect?token=nvbx_token',
    'source': 'clipboard',
  });

  regressionExpect(
    result != null,
    'payload with unknown source should still normalize',
  );
  regressionExpect(
    result!.source == PairingHandoffSource.manual,
    'unknown platform source tokens should not fabricate trusted provenance',
  );
}

void rejectsNonStringPayloadFields() {
  final result = NavivoxPlatformConnectIntentPayload.from({
    'payload': {'url': 'https://gateway.example/connect?token=nvbx_token'},
    'source': sharedTextPairingHandoffPlatformSource,
  });

  regressionExpect(
    result == null,
    'structured payload field must be a string, not Object.toString() text',
  );
}
