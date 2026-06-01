import '../../../../models/connection_import.dart';
import '../../../test_support/regression_expect.dart';
import '../contracts/navivox_platform_connect_intent_payload.dart';
import '../test_support/navivox_connect_intent_payload_fixtures.dart';
import 'navivox_connect_intent_payload.dart';

void main() {
  parsesPlainStringPayloadAsManualImport();
  preservesMapPayloadSourceProvenance();
  trimsPlatformSourceTokenBeforeMappingProvenance();
  mapsPlatformSourceTokenCaseInsensitively();
  parsesCaseInsensitiveDirectAppOpenCoreDescriptor();
  rejectsMalformedCaseInsensitiveDirectAppOpenCoreDescriptor();
  rejectsStructuredMapPayloadValuesInsteadOfParsingObjectStrings();
  rejectsStructuredSourceValuesInsteadOfParsingObjectStrings();
}

void parsesPlainStringPayloadAsManualImport() {
  final result = parseNavivoxConnectIntentPayload(
    ' $navivoxRegressionConnectIntentPayload ',
  );

  regressionExpect(result != null, 'plain string payload should parse');
  regressionExpect(
    result!.baseUrl == 'https://gateway.example',
    'plain string base URL should be derived from URL origin',
  );
  regressionExpect(
    result.token == 'nvbx_token',
    'plain string token should parse',
  );
  regressionExpect(
    result.source == PairingHandoffSource.manual,
    'plain string payloads have no platform provenance metadata',
  );
}

void preservesMapPayloadSourceProvenance() {
  final result = parseNavivoxConnectIntentPayload(
    navivoxPlatformConnectIntentPayloadFixture(),
  );

  regressionExpect(result != null, 'map payload should parse');
  regressionExpect(
    result!.source == PairingHandoffSource.sharedText,
    'shared_text source should be preserved',
  );
}

void trimsPlatformSourceTokenBeforeMappingProvenance() {
  final result = parseNavivoxConnectIntentPayload(
    navivoxPlatformConnectIntentPayloadFixture(
      source: ' $sharedTextPairingHandoffPlatformSource ',
    ),
  );

  regressionExpect(
    result != null,
    'map payload with padded source should parse',
  );
  regressionExpect(
    result!.source == PairingHandoffSource.sharedText,
    'platform source token should be trimmed before source mapping',
  );
}

void mapsPlatformSourceTokenCaseInsensitively() {
  final result = parseNavivoxConnectIntentPayload(
    navivoxPlatformConnectIntentPayloadFixture(
      source: ' ${sharedTextPairingHandoffPlatformSource.toUpperCase()} ',
    ),
  );

  regressionExpect(
    result != null,
    'map payload with uppercase source should parse',
  );
  regressionExpect(
    result!.source == PairingHandoffSource.sharedText,
    'platform source tokens should be case-insensitive after trimming',
  );
}

void parsesCaseInsensitiveDirectAppOpenCoreDescriptor() {
  final result = parseNavivoxConnectIntentPayload(
    navivoxPlatformConnectIntentPayloadFixture(
      payload:
          'NAVIVOX://CONNECT?websocket_url=ws%3A%2F%2Fgateway.example%2Fws&rest_token=nvbx_token&server_id=srv&profile_id=profile',
      source: directAppOpenPairingHandoffPlatformSource,
    ),
  );

  regressionExpect(
    result != null,
    'Android accepts direct app-open scheme/host case-insensitively, so Dart should parse the forwarded descriptor',
  );
  regressionExpect(
    result!.webSocketUrl == 'ws://gateway.example/ws',
    'case-insensitive direct app-open descriptor should preserve websocket URL',
  );
  regressionExpect(
    result.token == 'nvbx_token',
    'case-insensitive direct app-open descriptor should preserve REST token',
  );
  regressionExpect(
    result.source == PairingHandoffSource.directAppOpen,
    'case-insensitive direct app-open descriptor should preserve direct app-open provenance',
  );
}

void rejectsMalformedCaseInsensitiveDirectAppOpenCoreDescriptor() {
  final result = parseNavivoxConnectIntentPayload(
    navivoxPlatformConnectIntentPayloadFixture(
      payload: 'NAVIVOX://CONNECT?rest_token=nvbx_token_only',
      source: directAppOpenPairingHandoffPlatformSource,
    ),
  );

  regressionExpect(
    result == null,
    'case-insensitive direct app-open core descriptor must not bypass malformed navivox://connect rejection',
  );
}

void rejectsStructuredMapPayloadValuesInsteadOfParsingObjectStrings() {
  final result = parseNavivoxConnectIntentPayload(
    navivoxPlatformConnectIntentPayloadFixture(
      payload: {'url': navivoxRegressionConnectIntentPayload},
    ),
  );

  regressionExpect(
    result == null,
    'platform map payload field must be a string, not Object.toString() text',
  );
}

void rejectsStructuredSourceValuesInsteadOfParsingObjectStrings() {
  final result = parseNavivoxConnectIntentPayload(
    navivoxPlatformConnectIntentPayloadFixture(
      source: _StringLikePlatformSource(),
    ),
  );

  regressionExpect(
    result != null,
    'map payload with structured source should parse',
  );
  regressionExpect(
    result!.source == PairingHandoffSource.manual,
    'platform source field must be a string, not Object.toString() text',
  );
}

class _StringLikePlatformSource {
  @override
  String toString() => sharedTextPairingHandoffPlatformSource;
}
