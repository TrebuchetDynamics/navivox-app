import '../../../../shared/voice/voice_settings.dart';

class PocketSpeechDownloadSpec {
  const PocketSpeechDownloadSpec({
    required this.modelUrl,
    required this.voicesJsonUrl,
    required this.modelSha256,
    required this.voicesJsonSha256,
  });

  final String modelUrl;
  final String voicesJsonUrl;
  final String modelSha256;
  final String voicesJsonSha256;

  bool get isConfigured {
    final modelUri = Uri.tryParse(modelUrl.trim());
    final voicesUri = Uri.tryParse(voicesJsonUrl.trim());
    final hashPattern = RegExp(r'^[a-fA-F0-9]{64}$');
    return modelUri?.scheme == 'https' &&
        modelUri!.host.isNotEmpty &&
        voicesUri?.scheme == 'https' &&
        voicesUri!.host.isNotEmpty &&
        hashPattern.hasMatch(modelSha256.trim()) &&
        hashPattern.hasMatch(voicesJsonSha256.trim());
  }
}

class PocketSpeechAssetDownloadConfig {
  const PocketSpeechAssetDownloadConfig({
    required this.kitten,
    required this.kokoro,
  });

  factory PocketSpeechAssetDownloadConfig.fromEnvironment() =>
      const PocketSpeechAssetDownloadConfig(
        kitten: PocketSpeechDownloadSpec(
          modelUrl: String.fromEnvironment('KITTEN_MODEL_URL'),
          voicesJsonUrl: String.fromEnvironment('KITTEN_VOICES_JSON_URL'),
          modelSha256: String.fromEnvironment('KITTEN_MODEL_SHA256'),
          voicesJsonSha256: String.fromEnvironment('KITTEN_VOICES_JSON_SHA256'),
        ),
        kokoro: PocketSpeechDownloadSpec(
          modelUrl: String.fromEnvironment('KOKORO_MODEL_URL'),
          voicesJsonUrl: String.fromEnvironment('KOKORO_VOICES_JSON_URL'),
          modelSha256: String.fromEnvironment('KOKORO_MODEL_SHA256'),
          voicesJsonSha256: String.fromEnvironment('KOKORO_VOICES_JSON_SHA256'),
        ),
      );

  final PocketSpeechDownloadSpec kitten;
  final PocketSpeechDownloadSpec kokoro;

  PocketSpeechDownloadSpec specFor(PocketSpeechModel model) =>
      model == PocketSpeechModel.kitten ? kitten : kokoro;

  bool get hasConfiguredModel => kitten.isConfigured || kokoro.isConfigured;
}

abstract interface class PocketSpeechAssetDownloadService {
  bool isConfigured(PocketSpeechModel model);
  Future<PocketSpeechVoicePack> download(PocketSpeechModel model);
}
