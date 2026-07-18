part of 'settings_screen.dart';

final pocketSpeechVoiceNamesProvider = FutureProvider<List<String>>((ref) {
  final model = ref.watch(
    wingVoiceSettingsProvider.select((settings) => settings.pocketSpeechModel),
  );
  final path = ref.watch(
    wingVoiceSettingsProvider.select(
      (settings) => settings.pocketSpeechVoicePack?.voicesPath,
    ),
  );
  return switch (model) {
    PocketSpeechModel.kitten => Future.value(KittenCatalog.voices),
    PocketSpeechModel.kokoro => _kokoroVoiceNames(path),
  };
});

Future<List<String>> _kokoroVoiceNames(String? path) async {
  if (path == null) return const [];
  try {
    return await Isolate.run(() {
      final decoded = jsonDecode(File(path).readAsStringSync());
      return decoded is Map
          ? decoded.keys.map((key) => key.toString()).toList()
          : <String>[];
    });
  } catch (_) {
    return const [];
  }
}

class VoiceSettingsScreen extends ConsumerWidget {
  const VoiceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(wingVoiceSettingsProvider);
    final controller = ref.read(wingVoiceSettingsProvider.notifier);
    final pocketSpeechDownloader = ref.watch(
      _pocketSpeechAssetDownloadServiceProvider,
    );
    final pocketSpeechDownload = ref.watch(
      _pocketSpeechAssetDownloadingProvider,
    );
    final pocketSpeechVoices = ref.watch(pocketSpeechVoiceNamesProvider);
    final pocketSpeechPreviewing = ref.watch(_pocketSpeechPreviewingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Voice & speech')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsSectionCard(
            title: 'Voice behavior',
            icon: Icons.keyboard_voice_outlined,
            children: [
              _ConstrainedSettingsTile(
                child: SwitchListTile(
                  key: const ValueKey('voice-continuous-enabled'),
                  title: Text(_settingsPresentation.continuousVoiceTitle),
                  subtitle: Text(_settingsPresentation.continuousVoiceSubtitle),
                  value: settings.continuousVoiceEnabled,
                  onChanged: controller.setContinuousVoiceEnabled,
                ),
              ),
              _ConstrainedSettingsTile(
                child: SwitchListTile(
                  key: const ValueKey('voice-speak-replies-enabled'),
                  title: Text(_settingsPresentation.speakRepliesTitle),
                  subtitle: Text(_settingsPresentation.speakRepliesSubtitle),
                  value: settings.speakRepliesEnabled,
                  onChanged: controller.setSpeakRepliesEnabled,
                ),
              ),
            ],
          ),
          _PocketSpeechSettingsSection(
            settings: settings,
            controller: controller,
            downloader: pocketSpeechDownloader,
            download: pocketSpeechDownload,
            voices: pocketSpeechVoices,
            previewing: pocketSpeechPreviewing,
          ),
          _SettingsSectionCard(
            title: 'Advanced',
            icon: Icons.tune_outlined,
            children: [
              ExpansionTile(
                key: const ValueKey('voice-advanced-expansion'),
                title: const Text('Advanced'),
                children: [
                  ListTile(
                    key: const ValueKey('settings-command-word'),
                    title: Text(_settingsPresentation.commandWordTitle),
                    subtitle: Text(settings.commandWord),
                    trailing: const Icon(Icons.keyboard_voice),
                    onTap: () => _showCommandWordSheet(
                      context,
                      settings.commandWord,
                      controller.setCommandWord,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PocketSpeechSettingsSection extends ConsumerWidget {
  const _PocketSpeechSettingsSection({
    required this.settings,
    required this.controller,
    required this.downloader,
    required this.download,
    required this.voices,
    required this.previewing,
  });

  final WingVoiceSettings settings;
  final WingVoiceSettingsController controller;
  final PocketSpeechAssetDownloadService? downloader;
  final PocketSpeechDownloadProgress? download;
  final AsyncValue<List<String>> voices;
  final bool previewing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloading = download != null;
    return _SettingsSectionCard(
      title: _settingsPresentation.localVoiceSectionTitle,
      icon: Icons.graphic_eq,
      children: [
        ListTile(
          key: const ValueKey('voice-pocket-speech-model'),
          leading: const Icon(Icons.graphic_eq),
          title: const Text('Pocket Speech model'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose a compact English pack or the larger bilingual pack',
              ),
              Align(
                alignment: Alignment.centerRight,
                child: DropdownButton<PocketSpeechModel>(
                  value: settings.pocketSpeechModel,
                  items: [
                    for (final model in PocketSpeechModel.values)
                      DropdownMenuItem(value: model, child: Text(model.label)),
                  ],
                  onChanged: downloading
                      ? null
                      : (model) {
                          if (model != null) {
                            controller.setPocketSpeechModel(model);
                          }
                        },
                ),
              ),
            ],
          ),
        ),
        ListTile(
          key: const ValueKey('voice-pocket-speech-assets'),
          leading: Icon(
            settings.pocketSpeechVoicePackReady
                ? Icons.check_circle_outline
                : Icons.download_for_offline_outlined,
          ),
          title: Text('${settings.pocketSpeechModel.label} voice pack'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PocketSpeechAssetSubtitle(
                model: settings.pocketSpeechModel,
                ready: settings.pocketSpeechVoicePackReady,
                configured:
                    downloader?.isConfigured(settings.pocketSpeechModel) ==
                    true,
                progress: download,
              ),
              const SizedBox(height: 8),
              if (downloading)
                Text(
                  '${(download!.fraction * 100).round()}%',
                  style: Theme.of(context).textTheme.labelLarge,
                )
              else
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (settings.pocketSpeechVoicePackReady)
                        IconButton(
                          tooltip: 'Remove downloaded voice pack',
                          onPressed: downloader == null
                              ? null
                              : () => _deletePocketSpeechAssets(
                                  context,
                                  ref,
                                  controller,
                                  downloader!,
                                  settings.pocketSpeechModel,
                                ),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      FilledButton(
                        onPressed:
                            downloader?.isConfigured(
                                  settings.pocketSpeechModel,
                                ) ==
                                true
                            ? () => _downloadPocketSpeechAssets(
                                context,
                                ref,
                                controller,
                                downloader!,
                                settings.pocketSpeechModel,
                              )
                            : null,
                        child: Text(
                          settings.pocketSpeechVoicePackReady
                              ? 'Update'
                              : 'Download',
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        _ConstrainedSettingsTile(
          child: SwitchListTile(
            key: const ValueKey('voice-pocket-speech-enabled'),
            title: const Text('Use Pocket Speech for replies'),
            subtitle: Text(
              settings.pocketSpeechVoicePackReady
                  ? 'Use the installed ${settings.pocketSpeechModel.label} pack when Speak assistant replies is on'
                  : 'Download ${settings.pocketSpeechModel.label} before enabling',
            ),
            value: settings.pocketSpeechTtsEnabled,
            onChanged: settings.pocketSpeechVoicePackReady
                ? controller.setPocketSpeechTtsEnabled
                : null,
          ),
        ),
        ListTile(
          key: const ValueKey('voice-pocket-speech-voice'),
          leading: const Icon(Icons.record_voice_over_outlined),
          title: const Text('Offline voice'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                settings.pocketSpeechVoicePackReady
                    ? 'Voice used for Pocket Speech replies'
                    : 'Available after the voice pack is downloaded',
              ),
              Align(
                alignment: Alignment.centerRight,
                child: voices.when(
                  data: (availableVoices) {
                    final selected =
                        availableVoices.contains(settings.ttsVoiceName)
                        ? settings.ttsVoiceName
                        : null;
                    return DropdownButton<String?>(
                      value: selected,
                      hint: const Text('Default'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Default'),
                        ),
                        for (final voice in availableVoices)
                          DropdownMenuItem<String?>(
                            value: voice,
                            child: Text(
                              _pocketSpeechVoiceLabel(
                                settings.pocketSpeechModel,
                                voice,
                              ),
                            ),
                          ),
                      ],
                      onChanged: settings.pocketSpeechVoicePackReady
                          ? controller.setTtsVoiceName
                          : null,
                    );
                  },
                  loading: () => const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, _) => const Text('Unavailable'),
                ),
              ),
            ],
          ),
        ),
        ListTile(
          key: const ValueKey('voice-pocket-speech-speed'),
          leading: const Icon(Icons.speed_outlined),
          title: Text(
            'Reply speed · ${settings.speechRate.clamp(0.5, 2.0).toStringAsFixed(2)}×',
          ),
          subtitle: Slider(
            value: settings.speechRate.clamp(0.5, 2.0),
            min: 0.5,
            max: 2.0,
            divisions: 6,
            label: '${settings.speechRate.clamp(0.5, 2.0).toStringAsFixed(2)}×',
            onChanged: controller.setSpeechRate,
          ),
        ),
        ListTile(
          key: const ValueKey('voice-pocket-speech-preview'),
          leading: const Icon(Icons.play_circle_outline),
          title: const Text('Preview offline voice'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Play a local sample with the selected voice and speed',
              ),
              Align(
                alignment: Alignment.centerRight,
                child: previewing
                    ? const SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : OutlinedButton.icon(
                        onPressed: settings.pocketSpeechVoicePackReady
                            ? () => _previewPocketSpeech(context, ref, settings)
                            : null,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Preview'),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final _pocketSpeechAssetDownloadServiceProvider =
    Provider<PocketSpeechAssetDownloadService?>(
      (_) => createDefaultPocketSpeechAssetDownloadService(),
    );

class _PocketSpeechPreviewingController extends Notifier<bool> {
  @override
  bool build() => false;

  void setPreviewing(bool value) => state = value;
}

final _pocketSpeechPreviewingProvider =
    NotifierProvider<_PocketSpeechPreviewingController, bool>(
      _PocketSpeechPreviewingController.new,
    );

class _PocketSpeechAssetDownloadingController
    extends Notifier<PocketSpeechDownloadProgress?> {
  @override
  PocketSpeechDownloadProgress? build() => null;

  void start(PocketSpeechModel model) {
    state = PocketSpeechDownloadProgress(
      model: model,
      part: PocketSpeechDownloadPart.model,
      receivedBytes: 0,
      totalBytes: model.downloadBytes,
    );
  }

  void update(PocketSpeechDownloadProgress progress) => state = progress;

  void finish() => state = null;
}

final _pocketSpeechAssetDownloadingProvider =
    NotifierProvider<
      _PocketSpeechAssetDownloadingController,
      PocketSpeechDownloadProgress?
    >(_PocketSpeechAssetDownloadingController.new);

Future<void> _downloadPocketSpeechAssets(
  BuildContext context,
  WidgetRef ref,
  WingVoiceSettingsController controller,
  PocketSpeechAssetDownloadService downloader,
  PocketSpeechModel model,
) async {
  if (model == PocketSpeechModel.kokoro &&
      !await _confirmLargePocketSpeechDownload(context, model)) {
    return;
  }
  if (!context.mounted) return;

  final downloading = ref.read(_pocketSpeechAssetDownloadingProvider.notifier);
  downloading.start(model);
  try {
    final voicePack = await downloader.download(
      model,
      onProgress: downloading.update,
    );
    controller.setPocketSpeechVoicePack(voicePack);
    ref.invalidate(pocketSpeechVoiceNamesProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${model.label} voice pack is ready'),
          action: SnackBarAction(
            label: 'Use for replies',
            onPressed: () {
              controller.setPocketSpeechTtsEnabled(true);
              controller.setSpeakRepliesEnabled(true);
            },
          ),
        ),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${model.label} download failed. Check the connection and free storage, then retry.',
          ),
        ),
      );
    }
  } finally {
    downloading.finish();
  }
}

Future<bool> _confirmLargePocketSpeechDownload(
  BuildContext context,
  PocketSpeechModel model,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Download ${model.label}?'),
        content: Text(
          '${model.downloadSummary}. Keep Hermes Wing open until the verified download finishes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Download'),
          ),
        ],
      ),
    ) ??
    false;

Future<void> _deletePocketSpeechAssets(
  BuildContext context,
  WidgetRef ref,
  WingVoiceSettingsController controller,
  PocketSpeechAssetDownloadService downloader,
  PocketSpeechModel model,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Remove ${model.label} voice pack?'),
      content: Text(
        'This frees ${model.downloadSize} of app storage. You can download it again later.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Remove'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  try {
    await downloader.delete(model);
    controller.clearPocketSpeechVoicePack();
    ref.invalidate(pocketSpeechVoiceNamesProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${model.label} voice pack removed')),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not remove ${model.label} voice pack')),
      );
    }
  }
}

Future<void> _previewPocketSpeech(
  BuildContext context,
  WidgetRef ref,
  WingVoiceSettings settings,
) async {
  final voicePack = settings.pocketSpeechVoicePack;
  if (voicePack == null) return;

  final previewing = ref.read(_pocketSpeechPreviewingProvider.notifier);
  TextToSpeechService? service;
  previewing.setPreviewing(true);
  try {
    service = createPocketSpeechTextToSpeechService(
      enabled: true,
      voicePack: voicePack,
      settings: () => ref.read(wingVoiceSettingsProvider),
    );
    if (service == null) throw StateError('Pocket Speech preview unavailable');
    final spanishVoice =
        settings.pocketSpeechModel == PocketSpeechModel.kokoro &&
        (settings.ttsVoiceName?.startsWith('ef_') == true ||
            settings.ttsVoiceName?.startsWith('em_') == true);
    await service.speak(
      spanishVoice
          ? 'Hermes Wing responde con Pocket Speech.'
          : 'Hermes Wing is ready to speak.',
    );
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not preview this voice. Update the voice pack and try again.',
          ),
        ),
      );
    }
  } finally {
    try {
      await service?.dispose();
    } catch (_) {
      // Preview cleanup must not replace the actionable synthesis error.
    }
    previewing.setPreviewing(false);
  }
}

class _PocketSpeechAssetSubtitle extends StatelessWidget {
  const _PocketSpeechAssetSubtitle({
    required this.model,
    required this.ready,
    required this.configured,
    required this.progress,
  });

  final PocketSpeechModel model;
  final bool ready;
  final bool configured;
  final PocketSpeechDownloadProgress? progress;

  @override
  Widget build(BuildContext context) {
    final activeProgress = progress?.model == model ? progress : null;
    if (activeProgress != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${activeProgress.part.label} · ${_formatDownloadBytes(activeProgress.receivedBytes)} of ${_formatDownloadBytes(activeProgress.totalBytes)}',
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: activeProgress.fraction,
              semanticsLabel: '${model.label} download progress',
              semanticsValue:
                  '${(activeProgress.fraction * 100).round()} percent',
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(model.downloadSummary),
        Text(
          ready
              ? 'Installed and stored on this device for offline use'
              : configured
              ? 'Verified download; stored on this device. Keep the app open.'
              : 'Downloads are unavailable in this build',
        ),
      ],
    );
  }
}

String _pocketSpeechVoiceLabel(PocketSpeechModel model, String voice) {
  if (model != PocketSpeechModel.kokoro ||
      !KokoroCatalog.supportsVoice(voice)) {
    return voice;
  }
  final metadata = KokoroCatalog.voice(voice);
  final language = KokoroCatalog.language(metadata.languageCode);
  return '${metadata.name} · ${language.name}';
}

String _formatDownloadBytes(int bytes) =>
    '${(bytes / 1000 / 1000).toStringAsFixed(bytes < 100000000 ? 1 : 0)} MB';

class _ConstrainedSettingsTile extends StatelessWidget {
  const _ConstrainedSettingsTile({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 72),
      child: child,
    );
  }
}

Future<void> _showCommandWordSheet(
  BuildContext context,
  String commandWord,
  ValueChanged<String> onSave,
) async {
  final controller = TextEditingController(text: commandWord);
  await showModalBottomSheet<void>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Command word', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('settings-command-word-field'),
              controller: controller,
              autofocus: true,
              autocorrect: false,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(labelText: 'Command word'),
              onSubmitted: (value) {
                onSave(value);
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'Say this before “stop”, “pause”, “mute”, or “cancel” while the foreground voice loop is listening.',
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                key: const ValueKey('settings-command-word-save'),
                onPressed: () {
                  onSave(controller.text);
                  Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  controller.dispose();
}
