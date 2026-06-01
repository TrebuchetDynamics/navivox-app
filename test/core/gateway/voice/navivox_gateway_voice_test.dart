import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/gateway/voice/navivox_gateway_voice.dart';

void main() {
  group('Navivox voice credential status refs', () {
    test('drop non-string and blank adapter keys before status decoding', () {
      final profile = NavivoxVoiceProfileView.fromJson({
        'profile_id': 'mineru',
        'voice_profile': const {},
        'valid': true,
        'credential_status_refs': {
          ' stt ': {'configured': true, 'required': true, 'status': 'set'},
          ' ': {'configured': true, 'required': false, 'status': 'blank'},
          1: {'configured': true, 'required': false, 'status': 'number'},
          'tts': 'malformed',
        },
      });

      expect(profile.credentialStatusRefs.keys, ['stt']);
      expect(profile.credentialStatusRefs['stt']?.configured, isTrue);
      expect(profile.credentialStatusRefs['stt']?.required, isTrue);
      expect(profile.credentialStatusRefs['stt']?.status, 'set');
    });
  });
}
