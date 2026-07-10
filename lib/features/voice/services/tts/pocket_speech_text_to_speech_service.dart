// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:pocket_speech/pocket_speech.dart';

import '../../../../shared/voice/text_to_speech_service.dart';
import '../../../../shared/voice/voice_settings.dart';

abstract interface class PocketSpeechEngine {
  Future<Uint8List> synthesizeWav(String text);
  Future<void> dispose();
}

class PackagePocketSpeechEngine implements PocketSpeechEngine {
  PackagePocketSpeechEngine(PocketSpeechVoicePack voicePack) {
    switch (voicePack.model) {
      case PocketSpeechModel.kitten:
        final tts = PocketSpeech.kitten(
          KittenTtsConfig(
            modelAsset: voicePack.modelPath,
            voicesAsset: voicePack.voicesPath,
            model: KittenTtsModel.nanoInt8,
          ),
        );
        _synthesize = (text) => tts.synthesizeWav(text);
        _dispose = tts.dispose;
      case PocketSpeechModel.kokoro:
        final tts = PocketSpeech.kokoro(
          KokoroTtsConfig(
            modelAsset: voicePack.modelPath,
            voicesAsset: voicePack.voicesPath,
          ),
        );
        _synthesize = (text) => tts.synthesizeWav(text);
        _dispose = tts.dispose;
    }
  }

  late final Future<Uint8List> Function(String text) _synthesize;
  late final Future<void> Function() _dispose;

  @override
  Future<Uint8List> synthesizeWav(String text) => _synthesize(text);

  @override
  Future<void> dispose() => _dispose();
}

abstract interface class PocketSpeechAudioSink {
  Future<void> playWav(Uint8List wav);
  Future<void> stop();
  Future<void> dispose();
}

abstract interface class PocketSpeechAudioPlayer {
  Stream<void> get onPlayerComplete;
  Future<void> playBytes(Uint8List wav);
  Future<void> stop();
  Future<void> dispose();
}

class PackagePocketSpeechAudioPlayer implements PocketSpeechAudioPlayer {
  PackagePocketSpeechAudioPlayer({AudioPlayer? player})
    : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Stream<void> get onPlayerComplete => _player.onPlayerComplete;

  @override
  Future<void> playBytes(Uint8List wav) => _player.play(BytesSource(wav));

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}

class AudioPlayersPocketSpeechAudioSink implements PocketSpeechAudioSink {
  AudioPlayersPocketSpeechAudioSink({PocketSpeechAudioPlayer? player})
    : _player = player ?? PackagePocketSpeechAudioPlayer() {
    _completionSubscription = _player.onPlayerComplete.listen((_) {
      final completion = _playbackCompletion;
      if (completion != null && !completion.isCompleted) completion.complete();
    });
  }

  final PocketSpeechAudioPlayer _player;
  late final StreamSubscription<void> _completionSubscription;
  Completer<void>? _playbackCompletion;

  @override
  Future<void> playWav(Uint8List wav) async {
    await stop();
    final completion = Completer<void>();
    _playbackCompletion = completion;
    try {
      await _player.playBytes(wav);
      await completion.future;
    } finally {
      if (identical(_playbackCompletion, completion)) {
        _playbackCompletion = null;
      }
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _player.stop();
    } finally {
      final completion = _playbackCompletion;
      _playbackCompletion = null;
      if (completion != null && !completion.isCompleted) completion.complete();
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _completionSubscription.cancel();
    await _player.dispose();
  }
}

class PocketSpeechTextToSpeechService implements TextToSpeechService {
  PocketSpeechTextToSpeechService({
    required PocketSpeechEngine engine,
    required PocketSpeechAudioSink audioSink,
  }) : _engine = engine,
       _audioSink = audioSink;

  final PocketSpeechEngine _engine;
  final PocketSpeechAudioSink _audioSink;

  @override
  Future<void> speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final wav = await _engine.synthesizeWav(trimmed);
    if (wav.isEmpty) return;
    await _audioSink.playWav(wav);
  }

  @override
  Future<void> stop() => _audioSink.stop();

  @override
  Future<void> dispose() async {
    try {
      await _audioSink.dispose();
    } finally {
      await _engine.dispose();
    }
  }
}

TextToSpeechService? createPocketSpeechTextToSpeechService({
  bool enabled = false,
  PocketSpeechVoicePack? voicePack,
  PocketSpeechEngine? engine,
  PocketSpeechAudioSink? audioSink,
  bool useDefaultAudioSink = true,
}) {
  if (!enabled || (voicePack == null && engine == null)) return null;
  final effectiveSink =
      audioSink ??
      (useDefaultAudioSink ? AudioPlayersPocketSpeechAudioSink() : null);
  if (effectiveSink == null) return null;
  return PocketSpeechTextToSpeechService(
    engine: engine ?? PackagePocketSpeechEngine(voicePack!),
    audioSink: effectiveSink,
  );
}
