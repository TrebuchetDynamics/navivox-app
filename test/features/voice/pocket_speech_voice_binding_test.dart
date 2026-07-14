import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/voice/services/tts/pocket_speech_text_to_speech_service.dart';
import 'package:navivox/shared/voice/voice_settings.dart';

/// Fake [PocketSpeechEngine] that records the exact `(text, voice, speed)`
/// tuple passed to [synthesizeWav] for each call, so tests can assert on
/// what [PocketSpeechTextToSpeechService] actually threads through.
class _RecordingPocketSpeechEngine implements PocketSpeechEngine {
  final calls = <(String, String?, double)>[];

  @override
  Future<Uint8List> synthesizeWav(
    String text, {
    String? voice,
    double speed = 1.0,
  }) async {
    calls.add((text, voice, speed));
    return Uint8List.fromList([1]);
  }

  @override
  Future<void> dispose() async {}
}

class _NoopPocketSpeechAudioSink implements PocketSpeechAudioSink {
  @override
  Future<void> playWav(Uint8List wav) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

void main() {
  test(
    'no settings reader: back-compat default voice null, speed 1.0',
    () async {
      final engine = _RecordingPocketSpeechEngine();
      final service = PocketSpeechTextToSpeechService(
        engine: engine,
        audioSink: _NoopPocketSpeechAudioSink(),
      );

      await service.speak('hi');

      expect(engine.calls, [('hi', null, 1.0)]);
    },
  );

  test('settings reader with voice and rate applies both', () async {
    final engine = _RecordingPocketSpeechEngine();
    final service = PocketSpeechTextToSpeechService(
      engine: engine,
      audioSink: _NoopPocketSpeechAudioSink(),
      settings: () =>
          const NavivoxVoiceSettings(speechRate: 2.0, ttsVoiceName: 'Bella'),
    );

    await service.speak('hi');

    expect(engine.calls, [('hi', 'Bella', 2.0)]);
  });

  test(
    'settings reader present with default settings is augment-only',
    () async {
      final engine = _RecordingPocketSpeechEngine();
      final service = PocketSpeechTextToSpeechService(
        engine: engine,
        audioSink: _NoopPocketSpeechAudioSink(),
        settings: () => const NavivoxVoiceSettings(),
      );

      await service.speak('hi');

      expect(engine.calls, [('hi', null, 1.0)]);
    },
  );
}
