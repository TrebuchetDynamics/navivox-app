import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';

void main() {
  group('NavivoxVoiceCapability.captureUnavailableReason', () {
    test('keeps bare reported device STT unavailable informational', () {
      const capability = NavivoxVoiceCapability(
        deviceStt: 'unavailable',
        isReported: true,
      );

      expect(capability.captureUnavailableReason, isNull);
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
    test('keeps bare reported unavailable device STT enabled', () {
      const capability = NavivoxVoiceCapability(
        deviceStt: 'unavailable',
        isReported: true,
      );

      expect(capability.enabled, isTrue);
    });

    test('keeps unreported fallback unavailable values enabled', () {
      const capability = NavivoxVoiceCapability(deviceStt: 'unavailable');

      expect(capability.enabled, isTrue);
    });
  });

  group('NavivoxVoiceCapability.blocksDeviceCapture', () {
    test('does not block for reported device STT without recovery', () {
      const capability = NavivoxVoiceCapability(
        deviceStt: 'unavailable',
        isReported: true,
      );

      expect(capability.blocksDeviceCapture, isFalse);
    });

    test('does not block for an unreported fallback unavailable value', () {
      const capability = NavivoxVoiceCapability(deviceStt: 'unavailable');

      expect(capability.blocksDeviceCapture, isFalse);
    });

    test(
      'does not block when unavailable device STT only has recovery guidance',
      () {
        const capability = NavivoxVoiceCapability(
          deviceStt: ' unavailable ',
          recoveryAction: 'Enable device speech recognition',
        );

        expect(capability.captureUnavailableReason, isNull);
        expect(capability.blocksDeviceCapture, isFalse);
      },
    );
  });
}
