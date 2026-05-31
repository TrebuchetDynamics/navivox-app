import '../../../test_support/regression_expect.dart';
import '../contracts/navivox_platform_connect_intent_payload.dart';
import '../test_support/navivox_connect_intent_payload_fixtures.dart';
import 'navivox_connect_intent_initial_payload.dart';

void main() {
  preservesPayloadObservedDuringAvailabilityProbe();
  remembersNullAvailabilityProbePayload();
  keepsFirstUnconsumedProbePayloadAcrossRepeatedAvailabilityChecks();
}

void preservesPayloadObservedDuringAvailabilityProbe() {
  final cache = NavivoxInitialConnectIntentPayloadCache();
  final payload = navivoxPlatformConnectIntentPayloadFixture();

  cache.remember(payload);

  regressionExpect(
    cache.hasPayload,
    'availability probe payload should be marked cached',
  );
  regressionExpect(
    identical(cache.take(), payload),
    'initial import should consume the payload returned by the availability probe',
  );
  regressionExpect(
    !cache.hasPayload,
    'availability probe payload should be consumed only once',
  );
}

void remembersNullAvailabilityProbePayload() {
  final cache = NavivoxInitialConnectIntentPayloadCache();

  cache.remember(null);

  regressionExpect(
    cache.hasPayload,
    'null availability probe result should still be treated as a completed probe',
  );
  regressionExpect(
    cache.take() == null,
    'null availability probe result should be replayable without a second probe',
  );
  regressionExpect(
    !cache.hasPayload,
    'null probe result should be consumed only once',
  );
}

void keepsFirstUnconsumedProbePayloadAcrossRepeatedAvailabilityChecks() {
  final cache = NavivoxInitialConnectIntentPayloadCache();
  final firstPayload = navivoxPlatformConnectIntentPayloadFixture(
    source: directAppOpenPairingHandoffPlatformSource,
  );

  cache.remember(firstPayload);
  cache.remember(null);

  regressionExpect(
    identical(cache.take(), firstPayload),
    'repeated availability probes should not overwrite the first cached initial intent',
  );
}
