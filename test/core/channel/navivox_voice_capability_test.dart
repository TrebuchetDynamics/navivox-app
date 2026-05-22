import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';

void main() {
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
