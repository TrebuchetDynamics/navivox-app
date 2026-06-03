import 'package:flutter/material.dart';

import '../../presentation/chat_screen_presentation.dart';

class ContinuousVoiceControls extends StatelessWidget {
  const ContinuousVoiceControls({
    required this.presentation,
    required this.onTrustServer,
    required this.onCancelPending,
    required this.onOpenVoiceSettings,
    super.key,
  });

  final VoiceModePresentation presentation;
  final VoidCallback? onTrustServer;
  final VoidCallback onCancelPending;
  final VoidCallback onOpenVoiceSettings;

  @override
  Widget build(BuildContext context) {
    final text = presentation.bannerText;
    if (text == null) return const SizedBox.shrink();
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: InkWell(
        key: const ValueKey('continuous-voice-banner'),
        onTap: () => _showVoiceControls(context),
        child: Semantics(
          button: true,
          enabled: true,
          hint: presentation.controlsSemanticsHint,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  presentation.disabledReason == null
                      ? Icons.keyboard_voice
                      : Icons.mic_off,
                  size: 18,
                ),
                const SizedBox(width: 8),
                if (presentation.disabledReason == null) ...[
                  ContinuousVoiceLiveIndicator(active: presentation.pending),
                  const SizedBox(width: 8),
                ],
                Expanded(child: Text(text)),
                const Icon(Icons.tune, size: 18),
                if (presentation.pending)
                  TextButton(
                    onPressed: onCancelPending,
                    child: Text(presentation.cancelPendingButtonLabel),
                  ),
                if (!presentation.pending && presentation.canTrustServer)
                  TextButton(
                    onPressed: onTrustServer,
                    child: Text(presentation.trustServerButtonLabel),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showVoiceControls(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: DraggableScrollableSheet(
          key: const ValueKey('continuous-voice-control-sheet'),
          expand: false,
          initialChildSize: 0.86,
          minChildSize: 0.32,
          maxChildSize: 0.86,
          builder: (context, scrollController) => ListView(
            controller: scrollController,
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Text(
                presentation.sheetTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              for (final row in presentation.sheetRows)
                ListTile(
                  leading: Icon(
                    continuousVoiceControlRowIcon(
                      row.kind,
                      disabled: presentation.disabledReason != null,
                    ),
                  ),
                  title: Text(row.title),
                  subtitle: row.subtitle == null ? null : Text(row.subtitle!),
                  onTap: _voiceControlRowTap(context, row.action),
                ),
            ],
          ),
        ),
      ),
    );
  }

  VoidCallback? _voiceControlRowTap(
    BuildContext context,
    VoiceControlActionKind action,
  ) {
    return switch (action) {
      VoiceControlActionKind.none => null,
      VoiceControlActionKind.cancelPending => () {
        Navigator.of(context).pop();
        onCancelPending();
      },
      VoiceControlActionKind.openVoiceSettings => () {
        Navigator.of(context).pop();
        onOpenVoiceSettings();
      },
      VoiceControlActionKind.trustServer => () {
        Navigator.of(context).pop();
        onTrustServer?.call();
      },
    };
  }
}

class ContinuousVoiceLiveIndicator extends StatelessWidget {
  const ContinuousVoiceLiveIndicator({required this.active, super.key});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = active ? scheme.error : scheme.primary;
    return Row(
      key: const ValueKey('continuous-voice-live-indicator'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          key: const ValueKey('continuous-voice-live-dot'),
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        for (final height
            in active ? const [9.0, 14.0, 11.0] : const [7.0, 10.0, 8.0]) ...[
          Container(
            width: 3,
            height: height,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: active ? 0.9 : 0.55),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 2),
        ],
      ],
    );
  }
}

IconData continuousVoiceControlRowIcon(
  VoiceControlRowKind kind, {
  required bool disabled,
}) {
  return switch (kind) {
    VoiceControlRowKind.status =>
      disabled ? Icons.mic_off : Icons.keyboard_voice,
    VoiceControlRowKind.cancelPending => Icons.cancel_outlined,
    VoiceControlRowKind.recoveryAction => Icons.tips_and_updates_outlined,
    VoiceControlRowKind.openVoiceSettings => Icons.settings_voice_outlined,
    VoiceControlRowKind.diagnostics => Icons.fact_check_outlined,
    VoiceControlRowKind.androidRecognizer => Icons.android,
    VoiceControlRowKind.microphonePermission => Icons.mic_external_on_outlined,
    VoiceControlRowKind.gatewayProfileStt => Icons.cloud_outlined,
    VoiceControlRowKind.commandWord => Icons.short_text,
    VoiceControlRowKind.howItWorks => Icons.record_voice_over,
    VoiceControlRowKind.trustServer => Icons.verified_user_outlined,
  };
}
