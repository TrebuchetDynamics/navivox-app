import '../../../test_support/regression_expect.dart';
import '../contracts/navivox_platform_connect_intent_payload.dart';
import '../test_support/navivox_connect_intent_payload_fixtures.dart';
import 'navivox_connect_intent_initial_payload.dart';

void main() {
  preservesPayloadObservedDuringAvailabilityProbe();
  ignoresNullAvailabilityProbePayload();
  keepsFirstUnconsumedProbePayloadAcrossRepeatedAvailabilityChecks();
  exposesCacheWriteInvariant();
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

void ignoresNullAvailabilityProbePayload() {
  final cache = NavivoxInitialConnectIntentPayloadCache();

  cache.remember(null);

  regressionExpect(
    !cache.hasPayload,
    'null availability probe result should not mask a later non-null startup intent',
  );
}

void exposesCacheWriteInvariant() {
  regressionExpect(
    shouldRememberInitialConnectIntentPayload(false, 'payload'),
    'an empty cache should remember a non-null platform payload',
  );
  regressionExpect(
    !shouldRememberInitialConnectIntentPayload(false, null),
    'an empty probe is not a replayable startup intent payload',
  );
  regressionExpect(
    !shouldRememberInitialConnectIntentPayload(true, 'later'),
    'a cached startup intent payload must not be overwritten before take',
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
