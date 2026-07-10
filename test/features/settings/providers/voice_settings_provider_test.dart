import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navivox/features/settings/providers/voice_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'an immediate voice preference change wins over async preference load',
    () async {
      SharedPreferences.setMockInitialValues({
        'navivox.voice.continuous_enabled': true,
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(navivoxVoiceSettingsProvider.notifier);
      controller.setContinuousVoiceEnabled(false);
      await pumpEventQueue();

      expect(
        container.read(navivoxVoiceSettingsProvider).continuousVoiceEnabled,
        isFalse,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('navivox.voice.continuous_enabled'), isFalse);
    },
  );

  test(
    'selecting another Pocket Speech model clears the old voice pack',
    () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(navivoxVoiceSettingsProvider.notifier);

      controller.setPocketSpeechVoicePack(
        const PocketSpeechVoicePack(
          model: PocketSpeechModel.kokoro,
          modelPath: '/models/kokoro/model.onnx',
          voicesPath: '/models/kokoro/voices.json',
        ),
      );
      controller.setPocketSpeechTtsEnabled(true);
      controller.setPocketSpeechModel(PocketSpeechModel.kitten);

      final settings = container.read(navivoxVoiceSettingsProvider);
      expect(settings.pocketSpeechModel, PocketSpeechModel.kitten);
      expect(settings.pocketSpeechVoicePack, isNull);
      expect(settings.pocketSpeechTtsEnabled, isFalse);
      await pumpEventQueue();
    },
  );
}
