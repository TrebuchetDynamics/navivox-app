import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/voice/services/tts/text_to_speech_service.dart';
import 'package:navivox/shared/voice/voice_settings.dart';

/// Constructs the flutter_tts-backed [TextToSpeechService] under test. This
/// stands in for `buildFlutterTtsService` in the plan skeleton — the real
/// construction path is the `FlutterTextToSpeechService` constructor.
TextToSpeechService buildFlutterTtsService({
  required FlutterTtsEngine engine,
  required TtsSettingsReader settings,
}) => FlutterTextToSpeechService(engine: engine, settings: settings);

class _RecordingEngine implements FlutterTtsEngine {
  final calls = <String>[];
  bool failVoice = false;

  @override
  Future<void> awaitSpeakCompletion(bool awaitCompletion) async {
    calls.add('awaitSpeakCompletion:$awaitCompletion');
  }

  @override
  Future<void> setLanguage(String language) async {
    calls.add('setLanguage:$language');
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    calls.add('rate:$rate');
  }

  @override
  Future<void> setVolume(double volume) async {
    calls.add('setVolume:$volume');
  }

  @override
  Future<void> setPitch(double pitch) async {
    calls.add('setPitch:$pitch');
  }

  @override
  Future<void> speak(String text) async {
    calls.add('speak');
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
  }

  @override
  Future<List<String>> voiceNames() async => const ['nova', 'en-GB-standard'];

  @override
  Future<void> setVoiceByName(String name) async {
    if (failVoice) {
      throw StateError('Unknown TTS voice: $name');
    }
    calls.add('voice:$name');
  }
}

void main() {
  test('speak applies clamped rate and voice before speaking', () async {
    final engine = _RecordingEngine();
    final service = buildFlutterTtsService(
      engine: engine,
      settings: () =>
          const NavivoxVoiceSettings(speechRate: 1.5, ttsVoiceName: 'nova'),
    );
    await service.speak('hello');
    expect(
      engine.calls,
      containsAllInOrder(['rate:0.75', 'voice:nova', 'speak']),
    );
  });

  test('unknown voice is swallowed, speech still happens', () async {
    final engine = _RecordingEngine()..failVoice = true;
    final service = buildFlutterTtsService(
      engine: engine,
      settings: () => const NavivoxVoiceSettings(ttsVoiceName: 'ghost'),
    );
    await service.speak('hello');
    expect(engine.calls, contains('speak'));
  });
}
