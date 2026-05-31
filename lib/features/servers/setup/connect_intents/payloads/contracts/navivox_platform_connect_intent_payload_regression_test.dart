import '../../../../models/connection_import.dart';
import '../../../test_support/regression_expect.dart';
import 'navivox_platform_connect_intent_payload.dart';
import '../test_support/navivox_connect_intent_payload_fixtures.dart';

void main() {
  normalizesPlainStringPayloadAsManualSource();
  normalizesStructuredPayloadAndSourceToken();
  fallsBackToManualForUnknownPlatformSourceToken();
  rejectsNonStringPayloadFields();
}

void normalizesPlainStringPayloadAsManualSource() {
  final result = NavivoxPlatformConnectIntentPayload.from(
    ' $navivoxRegressionConnectIntentPayload ',
  );

  regressionExpect(result != null, 'plain string payload should normalize');
  regressionExpect(
    result!.text == navivoxRegressionConnectIntentPayload,
    'plain string payload text should be trimmed',
  );
  regressionExpect(
    result.source == PairingHandoffSource.manual,
    'plain string payloads have no platform provenance metadata',
  );
}

void normalizesStructuredPayloadAndSourceToken() {
  final result = NavivoxPlatformConnectIntentPayload.from(
    navivoxPlatformConnectIntentPayloadFixture(
      payload: ' $navivoxRegressionConnectIntentPayload ',
      source: directAppOpenPairingHandoffPlatformSource.toUpperCase(),
    ),
  );

  regressionExpect(result != null, 'structured payload should normalize');
  regressionExpect(
    result!.text == navivoxRegressionConnectIntentPayload,
    'structured payload text should be trimmed',
  );
  regressionExpect(
    result.source == PairingHandoffSource.directAppOpen,
    'platform source tokens should be trimmed and case-insensitive',
  );
}

void fallsBackToManualForUnknownPlatformSourceToken() {
  final result = NavivoxPlatformConnectIntentPayload.from(
    navivoxPlatformConnectIntentPayloadFixture(source: 'clipboard'),
  );

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
  final result = NavivoxPlatformConnectIntentPayload.from(
    navivoxPlatformConnectIntentPayloadFixture(
      payload: {'url': navivoxRegressionConnectIntentPayload},
    ),
  );

  regressionExpect(
    result == null,
    'structured payload field must be a string, not Object.toString() text',
  );
}
