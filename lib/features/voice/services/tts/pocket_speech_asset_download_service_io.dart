import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../shared/voice/voice_settings.dart';
import 'pocket_speech_asset_download_service_base.dart';

class IoPocketSpeechAssetDownloadService
    implements PocketSpeechAssetDownloadService {
  const IoPocketSpeechAssetDownloadService({required this.config});

  final PocketSpeechAssetDownloadConfig config;

  @override
  bool isConfigured(PocketSpeechModel model) =>
      config.specFor(model).isConfigured;

  @override
  Future<PocketSpeechVoicePack> download(PocketSpeechModel model) async {
    final spec = config.specFor(model);
    if (!spec.isConfigured) {
      throw StateError('${model.label} download is not configured.');
    }
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/pocket_speech/${model.name}');
    await dir.create(recursive: true);
    final modelFile = File('${dir.path}/model.onnx');
    final voicesFile = File('${dir.path}/voices.json');
    final modelTemp = File('${modelFile.path}.download');
    final voicesTemp = File('${voicesFile.path}.download');
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20);
    try {
      await _download(
        client,
        spec.modelUrl,
        modelTemp,
        expectedSha256: spec.modelSha256,
        maximumBytes: model == PocketSpeechModel.kokoro
            ? 500 * 1024 * 1024
            : 100 * 1024 * 1024,
      );
      await _download(
        client,
        spec.voicesJsonUrl,
        voicesTemp,
        expectedSha256: spec.voicesJsonSha256,
        maximumBytes: 20 * 1024 * 1024,
      );
      final decoded = jsonDecode(await voicesTemp.readAsString());
      if (decoded is! Map && decoded is! List) {
        throw const FormatException('Pocket Speech voices must be JSON.');
      }
      await _replace(modelTemp, modelFile);
      await _replace(voicesTemp, voicesFile);
    } finally {
      client.close(force: true);
      if (await modelTemp.exists()) await modelTemp.delete();
      if (await voicesTemp.exists()) await voicesTemp.delete();
    }
    return PocketSpeechVoicePack(
      model: model,
      modelPath: modelFile.path,
      voicesPath: voicesFile.path,
    );
  }

  Future<void> _download(
    HttpClient client,
    String url,
    File file, {
    required String expectedSha256,
    required int maximumBytes,
  }) async {
    if (await file.exists()) await file.delete();
    final response = await _openHttps(client, Uri.parse(url));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('GET $url failed with ${response.statusCode}');
    }
    final sink = file.openWrite();
    var received = 0;
    try {
      await for (final chunk in response.timeout(const Duration(seconds: 30))) {
        received += chunk.length;
        if (received > maximumBytes) {
          throw StateError('Pocket Speech asset exceeded its size limit.');
        }
        sink.add(chunk);
      }
    } finally {
      await sink.close();
    }
    final digest = await sha256.bind(file.openRead()).first;
    if (digest.toString().toLowerCase() !=
        expectedSha256.trim().toLowerCase()) {
      throw StateError('Pocket Speech asset checksum mismatch.');
    }
  }

  Future<HttpClientResponse> _openHttps(HttpClient client, Uri uri) async {
    var current = uri;
    for (var redirects = 0; redirects <= 5; redirects++) {
      final request = await client.getUrl(current);
      request.followRedirects = false;
      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );
      if (!const {
        HttpStatus.movedPermanently,
        HttpStatus.found,
        HttpStatus.seeOther,
        HttpStatus.temporaryRedirect,
        HttpStatus.permanentRedirect,
      }.contains(response.statusCode)) {
        return response;
      }
      final location = response.headers.value(HttpHeaders.locationHeader);
      await response.drain<void>();
      if (location == null || redirects == 5) {
        throw HttpException(
          'Pocket Speech asset redirect failed.',
          uri: current,
        );
      }
      final next = current.resolve(location);
      if (next.scheme != 'https' || next.host.isEmpty) {
        throw StateError('Pocket Speech asset redirect must use HTTPS.');
      }
      current = next;
    }
    throw StateError('Pocket Speech asset redirected too many times.');
  }

  Future<void> _replace(File source, File destination) async {
    final backup = File('${destination.path}.backup');
    if (await backup.exists()) await backup.delete();
    final hadDestination = await destination.exists();
    if (hadDestination) await destination.rename(backup.path);
    try {
      await source.rename(destination.path);
      if (await backup.exists()) await backup.delete();
    } catch (_) {
      if (await destination.exists()) await destination.delete();
      if (await backup.exists()) await backup.rename(destination.path);
      rethrow;
    }
  }
}

PocketSpeechAssetDownloadService?
createDefaultPocketSpeechAssetDownloadService({
  PocketSpeechAssetDownloadConfig? config,
}) {
  final effective = config ?? PocketSpeechAssetDownloadConfig.fromEnvironment();
  return effective.hasConfiguredModel
      ? IoPocketSpeechAssetDownloadService(config: effective)
      : null;
}
