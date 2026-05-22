import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';

void main() {
  group('NavivoxVoiceCapability.captureUnavailableReason', () {
    test('reports canonical device STT unavailable for blocked capture', () {
      const capability = NavivoxVoiceCapability(
        deviceStt: 'unavailable',
        isReported: true,
      );

      expect(capability.captureUnavailableReason, 'device STT unavailable');
    });

    test('returns canonical trimmed disabled reason', () {
      const capability = NavivoxVoiceCapability(
        disabledReason: ' Device STT unavailable ',
      );

      expect(capability.captureUnavailableReason, 'device STT unavailable');
    });

    test('keeps unreported fallback unavailable values available', () {
      const capability = NavivoxVoiceCapability(deviceStt: 'unavailable');

      expect(capability.captureUnavailableReason, isNull);
    });
  });

  group('NavivoxVoiceCapability.enabled', () {
    test('is false when reported unavailable device STT blocks capture', () {
      const capability = NavivoxVoiceCapability(
        deviceStt: 'unavailable',
        isReported: true,
      );

      expect(capability.enabled, isFalse);
    });

    test('keeps unreported fallback unavailable values enabled', () {
      const capability = NavivoxVoiceCapability(deviceStt: 'unavailable');

      expect(capability.enabled, isTrue);
    });
  });

  group('NavivoxVoiceCapability.blocksDeviceCapture', () {
    test('blocks when reported device STT is unavailable without recovery', () {
      const capability = NavivoxVoiceCapability(
        deviceStt: 'unavailable',
        isReported: true,
      );

      expect(capability.blocksDeviceCapture, isTrue);
    });

    test('does not block for an unreported fallback unavailable value', () {
      const capability = NavivoxVoiceCapability(deviceStt: 'unavailable');

      expect(capability.blocksDeviceCapture, isFalse);
    });

    test('blocks when unavailable device STT includes recovery guidance', () {
      const capability = NavivoxVoiceCapability(
        deviceStt: ' unavailable ',
        recoveryAction: 'Enable device speech recognition',
      );

      expect(capability.blocksDeviceCapture, isTrue);
    });
  });
}
