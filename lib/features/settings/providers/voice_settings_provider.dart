import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/voice/voice_settings.dart';

export '../../../shared/voice/voice_settings.dart';

class NavivoxVoiceSettingsController extends Notifier<NavivoxVoiceSettings> {
  static const _keyVoiceEnabled = 'navivox.voice.continuous_enabled';
  static const _keySpeakReplies = 'navivox.voice.speak_replies_enabled';
  // Keep legacy key values so existing Kokoro installs migrate in place.
  static const _keyPocketSpeechEnabled = 'navivox.voice.kokoro_tts_enabled';
  static const _keyPocketSpeechModel = 'navivox.voice.pocket_speech_model';
  static const _keyModelPath = 'navivox.voice.kokoro_model_path';
  static const _keyVoicesPath = 'navivox.voice.kokoro_voices_path';
  static const _keyCommandWord = 'navivox.voice.command_word';

  SharedPreferences? _prefs;
  int _mutationGeneration = 0;

  @override
  NavivoxVoiceSettings build() {
    _loadPrefs();
    return const NavivoxVoiceSettings();
  }

  Future<void> _loadPrefs() async {
    final loadGeneration = _mutationGeneration;
    try {
      _prefs = await SharedPreferences.getInstance();
      if (loadGeneration != _mutationGeneration) {
        await _save();
        return;
      }
      final enabled = _prefs?.getBool(_keyVoiceEnabled) ?? true;
      final speakReplies = _prefs?.getBool(_keySpeakReplies) ?? false;
      final pocketSpeechEnabled =
          _prefs?.getBool(_keyPocketSpeechEnabled) ?? false;
      final modelPath = _prefs?.getString(_keyModelPath);
      final voicesPath = _prefs?.getString(_keyVoicesPath);
      final savedModel = _prefs?.getString(_keyPocketSpeechModel);
      final model = PocketSpeechModel.values.firstWhere(
        (candidate) => candidate.name == savedModel,
        // Existing path-only settings came from the Kokoro-only integration.
        orElse: () => modelPath?.isNotEmpty == true
            ? PocketSpeechModel.kokoro
            : PocketSpeechModel.kitten,
      );
      final voicePack =
          modelPath?.isNotEmpty == true && voicesPath?.isNotEmpty == true
          ? PocketSpeechVoicePack(
              model: model,
              modelPath: modelPath!,
              voicesPath: voicesPath!,
            )
          : null;
      final commandWord = _prefs?.getString(_keyCommandWord) ?? 'navi';
      state = NavivoxVoiceSettings(
        continuousVoiceEnabled: enabled,
        speakRepliesEnabled: speakReplies,
        pocketSpeechTtsEnabled: pocketSpeechEnabled,
        pocketSpeechModel: model,
        pocketSpeechVoicePack: voicePack,
        commandWord: commandWord,
      );
    } catch (_) {
      state = const NavivoxVoiceSettings();
    }
  }

  Future<void> _save() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setBool(_keyVoiceEnabled, state.continuousVoiceEnabled);
    await prefs.setBool(_keySpeakReplies, state.speakRepliesEnabled);
    await prefs.setBool(_keyPocketSpeechEnabled, state.pocketSpeechTtsEnabled);
    await prefs.setString(_keyPocketSpeechModel, state.pocketSpeechModel.name);
    final voicePack = state.pocketSpeechVoicePack;
    if (voicePack == null) {
      await prefs.remove(_keyModelPath);
      await prefs.remove(_keyVoicesPath);
    } else {
      await prefs.setString(_keyModelPath, voicePack.modelPath);
      await prefs.setString(_keyVoicesPath, voicePack.voicesPath);
    }
    await prefs.setString(_keyCommandWord, state.commandWord);
  }

  void setContinuousVoiceEnabled(bool enabled) {
    _mutationGeneration += 1;
    state = state.copyWith(continuousVoiceEnabled: enabled);
    _save();
  }

  void setSpeakRepliesEnabled(bool enabled) {
    _mutationGeneration += 1;
    state = state.copyWith(speakRepliesEnabled: enabled);
    _save();
  }

  void setPocketSpeechTtsEnabled(bool enabled) {
    if (enabled && !state.pocketSpeechVoicePackReady) return;
    _mutationGeneration += 1;
    state = state.copyWith(pocketSpeechTtsEnabled: enabled);
    _save();
  }

  void setPocketSpeechModel(PocketSpeechModel model) {
    if (model == state.pocketSpeechModel) return;
    _mutationGeneration += 1;
    state = state.copyWith(
      pocketSpeechModel: model,
      pocketSpeechTtsEnabled: false,
      clearPocketSpeechVoicePack: true,
    );
    _save();
  }

  void setPocketSpeechVoicePack(PocketSpeechVoicePack voicePack) {
    _mutationGeneration += 1;
    state = state.copyWith(
      pocketSpeechModel: voicePack.model,
      pocketSpeechVoicePack: voicePack,
    );
    _save();
  }

  void clearPocketSpeechVoicePack() {
    _mutationGeneration += 1;
    state = state.copyWith(
      pocketSpeechTtsEnabled: false,
      clearPocketSpeechVoicePack: true,
    );
    _save();
  }

  void setCommandWord(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty || normalized.contains(RegExp(r'\s'))) return;
    _mutationGeneration += 1;
    state = state.copyWith(commandWord: normalized);
    _save();
  }
}

final navivoxVoiceSettingsProvider =
    NotifierProvider<NavivoxVoiceSettingsController, NavivoxVoiceSettings>(
      NavivoxVoiceSettingsController.new,
    );
