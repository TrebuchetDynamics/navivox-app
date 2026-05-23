import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/channel/navivox_channel.dart';
import '../../../core/channel/navivox_channel_provider.dart';
import '../../../core/protocol/navivox_event.dart';
import '../../../router/app_routes.dart';
import '../../settings/providers/voice_settings_provider.dart';
import '../../voice/services/default_voice_capture_service.dart';
import '../../voice/services/text_to_speech_service.dart';
import '../../voice/services/voice_capture_service.dart';
import '../chat_screen_presentation.dart';
import '../forward_message_intent.dart';
import '../local_command_dispatcher.dart';
import '../local_command_intent.dart';
import '../voice_run_controller.dart';
import '../widgets/approval_banner.dart';
import '../widgets/transcript_surface.dart';

/// Voice-capture service used by the chat input bar. Override in tests with
/// [FakeVoiceCaptureService]; Android production uses platform speech-to-text.
final chatVoiceCaptureServiceProvider = Provider<VoiceCaptureService?>(
  (_) => createDefaultVoiceCaptureService(),
);

final chatTextToSpeechServiceProvider = Provider<TextToSpeechService?>(
  (_) => null,
);

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    this.serverId,
    this.profileId,
    this.voiceCaptureServiceOverride,
    this.voiceAutoSendGrace = const Duration(milliseconds: 800),
    this.voiceCommandTimeout = const Duration(seconds: 5),
    super.key,
  });

  final String? serverId;
  final String? profileId;
  final VoiceCaptureService? voiceCaptureServiceOverride;
  final Duration voiceAutoSendGrace;
  final Duration voiceCommandTimeout;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  NavivoxChannel? _subscribed;
  final ForwardMessageIntent _forwardMessageIntent =
      const ForwardMessageIntent();
  final LocalCommandResolver _localCommandResolver =
      const LocalCommandResolver();
  final LocalCommandDispatcher _localCommandDispatcher =
      const LocalCommandDispatcher();
  final VoiceRunController _voiceRunController = VoiceRunController();
  Timer? _pendingVoiceTimer;
  Timer? _commandModeTimer;
  bool _commandMode = false;
  bool _routeProfileSynced = false;
  String? _lastRouteProfileKey;

  void _onChannelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _subscribed?.removeListener(_onChannelChanged);
    _pendingVoiceTimer?.cancel();
    _commandModeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final channel = ref.watch(navivoxChannelProvider);
    if (!identical(_subscribed, channel)) {
      _subscribed?.removeListener(_onChannelChanged);
      channel.addListener(_onChannelChanged);
      _subscribed = channel;
    }
    _syncRouteProfile(channel);

    final state = channel.state;
    final voiceService =
        widget.voiceCaptureServiceOverride ??
        ref.watch(chatVoiceCaptureServiceProvider);
    final textToSpeechService = ref.watch(chatTextToSpeechServiceProvider);
    final voiceSettings = ref.watch(navivoxVoiceSettingsProvider);
    final presentation = ChatScreenPresentation.fromState(
      state: state,
      voiceSettings: voiceSettings,
      localVoiceCaptureAvailable: voiceService != null,
      runtimeVoiceDisabledReason:
          _voiceRunController.runtimeVoiceDisabledReason,
      notice: _voiceRunController.notice,
      commandMode: _commandMode,
    );
    final activeProfile = presentation.activeProfile;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            final router = GoRouter.maybeOf(context);
            if (router != null) {
              router.go(AppRoutes.chats);
              return;
            }
            Navigator.of(context).maybePop();
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(presentation.appBarTitle),
            if (presentation.appBarSubtitle != null)
              Text(
                presentation.appBarSubtitle!,
                style: Theme.of(context).textTheme.labelMedium,
              ),
          ],
        ),
        actions: [
          IconButton(
            key: const ValueKey('chat-context-action'),
            tooltip: presentation.chatInfoTooltip,
            onPressed: () => _showChatInfo(context, presentation),
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          ApprovalBanner(channel: channel),
          _VoiceModeBanner(
            presentation: presentation.voiceMode,
            onTrustServer: activeProfile == null
                ? null
                : () => ref
                      .read(navivoxVoiceSettingsProvider.notifier)
                      .setServerTrusted(activeProfile.serverId, true),
            onCancelPending: _cancelPendingVoice,
          ),
          Expanded(
            child: TranscriptSurface(
              messages: presentation.transcriptMessages,
              onSend: (text) => _handleTextSubmit(channel, text),
              voiceCaptureService: presentation.voiceMode.disabledReason == null
                  ? voiceService
                  : null,
              voiceUnavailableReason: presentation.voiceMode.disabledReason,
              voiceRecoveryAction: presentation.voiceMode.recoveryAction,
              onOpenVoiceSettings: () => context.go(AppRoutes.settings),
              textToSpeechService: textToSpeechService,
              assistantTypingLabel: presentation.assistantTypingLabel,
              onCancelActiveTurn: presentation.assistantTypingLabel != null
                  ? () => channel.cancelActiveTurn()
                  : null,
              onVoice: (capture) => _handleVoiceCapture(channel, capture),
              onVoiceCaptureStarted: () {
                _voiceRunController.startCapture(channel);
              },
              onVoiceCaptureFailed: (error) {
                _voiceRunController.captureFailed(channel, error);
                setState(() {});
              },
              forwardTargets: presentation.forwardTargets,
              onForward: (message, target) =>
                  _handleForward(channel, message: message, target: target),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showChatInfo(
    BuildContext context,
    ChatScreenPresentation presentation,
  ) {
    final theme = Theme.of(context);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(
                presentation.chatInfoTitle,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              for (final row in presentation.infoRows)
                _ChatInfoRow(
                  icon: _chatInfoIcon(row.kind),
                  label: row.label,
                  value: row.value,
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _chatInfoIcon(ChatInfoRowKind kind) {
    return switch (kind) {
      ChatInfoRowKind.profile => Icons.person,
      ChatInfoRowKind.profileId => Icons.badge_outlined,
      ChatInfoRowKind.server => Icons.dns,
      ChatInfoRowKind.serverId => Icons.tag,
      ChatInfoRowKind.status => Icons.circle,
      ChatInfoRowKind.agent => Icons.smart_toy,
      ChatInfoRowKind.selectProfile => Icons.chat_bubble_outline,
    };
  }

  NavivoxVoiceSettings _voiceSettings(WidgetRef ref) {
    return ref.read(navivoxVoiceSettingsProvider);
  }

  void _handleTextSubmit(NavivoxChannel channel, String text) {
    if (_handleLocalCommand(channel, text, fromVoice: false)) return;
    channel.sendText(text);
  }

  void _handleForward(
    NavivoxChannel channel, {
    required NavivoxChatMessage message,
    required NavivoxProfileContact target,
  }) {
    final result = _forwardMessageIntent.forward(
      channel,
      message: message,
      target: target,
    );
    if (!result.forwarded) return;
    final routeLocation = result.routeLocation;
    if (routeLocation != null) {
      GoRouter.maybeOf(context)?.go(routeLocation);
    }
    final snackbarMessage = result.snackbarMessage;
    if (snackbarMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(snackbarMessage)));
    }
  }

  void _handleVoiceCapture(NavivoxChannel channel, VoiceCapture capture) {
    _pendingVoiceTimer?.cancel();
    final result = _voiceRunController.captureSucceeded(
      channel,
      capture,
      handleLocalCommand: (transcript) =>
          _handleLocalCommand(channel, transcript, fromVoice: true),
    );
    final voiceRunId = result.scheduleAutoSendFor;
    if (voiceRunId == null) {
      if (result.handledLocalCommand) setState(() {});
      return;
    }

    setState(() {});
    _pendingVoiceTimer = Timer(widget.voiceAutoSendGrace, () {
      if (!mounted) return;
      final result = _voiceRunController.autoSendIfPending(channel, voiceRunId);
      if (result.submitted) setState(() {});
    });
  }

  void _cancelPendingVoice() {
    _pendingVoiceTimer?.cancel();
    _voiceRunController.cancelPending(_subscribed);
    setState(() {});
  }

  bool _handleLocalCommand(
    NavivoxChannel channel,
    String raw, {
    required bool fromVoice,
  }) {
    final settings = _voiceSettings(ref);
    final intent = _localCommandResolver.resolve(
      raw: raw,
      commandWord: settings.commandWord,
      commandMode: _commandMode,
      fromVoice: fromVoice,
      profileSwitchingEnabled: settings.profileSwitchingEnabled,
      contacts: channel.state.profileContacts,
    );
    if (!intent.consumesInput) return false;
    final result = _localCommandDispatcher.dispatch(channel, intent);
    return _applyLocalCommandDispatchResult(result);
  }

  void _enterCommandMode() {
    _commandModeTimer?.cancel();
    setState(() {
      _commandMode = true;
      _voiceRunController.notice = 'Command mode';
    });
    _commandModeTimer = Timer(widget.voiceCommandTimeout, () {
      if (!mounted) return;
      setState(() {
        _commandMode = false;
        _voiceRunController.notice = 'Command mode timed out.';
      });
    });
  }

  void _exitCommandMode({required bool clearNotice}) {
    _commandModeTimer?.cancel();
    if (!_commandMode && !clearNotice) return;
    setState(() {
      _commandMode = false;
      if (clearNotice) _voiceRunController.notice = null;
    });
  }

  bool _applyLocalCommandDispatchResult(LocalCommandDispatchResult result) {
    if (!result.consumed) return false;
    if (result.enterCommandMode) {
      _enterCommandMode();
      return true;
    }
    _exitCommandMode(clearNotice: false);
    if (result.cancelPendingVoice) {
      _cancelPendingVoice();
    }
    final routeLocation = result.routeLocation;
    if (routeLocation != null) {
      GoRouter.maybeOf(context)?.go(routeLocation);
    }
    final message = result.message;
    if (message != null) {
      _showCommandMessage(message);
    }
    return true;
  }

  void _showCommandMessage(String message) {
    setState(() => _voiceRunController.notice = message);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _syncRouteProfile(NavivoxChannel channel) {
    final serverId = widget.serverId;
    final profileId = widget.profileId;
    if (serverId == null || profileId == null) return;

    final key = '$serverId::$profileId';
    if (_lastRouteProfileKey != key) {
      _lastRouteProfileKey = key;
      _voiceRunController.runtimeVoiceDisabledReason = null;
      _routeProfileSynced = false;
    }
    if (_routeProfileSynced) return;
    if (channel.state.selectedProfileContactKey == key &&
        channel.state.activeServerId == serverId) {
      _routeProfileSynced = true;
      return;
    }
    final exists = channel.state.profileContacts.any(
      (contact) =>
          contact.serverId == serverId && contact.profileId == profileId,
    );
    if (!exists) {
      _routeProfileSynced = true;
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (channel.state.selectedProfileContactKey == key &&
          channel.state.activeServerId == serverId) {
        _routeProfileSynced = true;
        return;
      }
      channel.selectProfileContact(serverId: serverId, profileId: profileId);
      _routeProfileSynced = true;
    });
  }
}

class _ChatInfoRow extends StatelessWidget {
  const _ChatInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label, style: theme.textTheme.labelLarge),
      subtitle: Text(value),
    );
  }
}

class _VoiceModeBanner extends StatelessWidget {
  const _VoiceModeBanner({
    required this.presentation,
    required this.onTrustServer,
    required this.onCancelPending,
  });

  final VoiceModePresentation presentation;
  final VoidCallback? onTrustServer;
  final VoidCallback onCancelPending;

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
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
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
                leading: Icon(_voiceControlRowIcon(row.kind)),
                title: Text(row.title),
                subtitle: row.subtitle == null ? null : Text(row.subtitle!),
                onTap: _voiceControlRowTap(context, row.action),
              ),
          ],
        ),
      ),
    );
  }

  IconData _voiceControlRowIcon(VoiceControlRowKind kind) {
    return switch (kind) {
      VoiceControlRowKind.status =>
        presentation.disabledReason == null
            ? Icons.keyboard_voice
            : Icons.mic_off,
      VoiceControlRowKind.cancelPending => Icons.cancel_outlined,
      VoiceControlRowKind.recoveryAction => Icons.tips_and_updates_outlined,
      VoiceControlRowKind.openVoiceSettings => Icons.settings_voice_outlined,
      VoiceControlRowKind.diagnostics => Icons.fact_check_outlined,
      VoiceControlRowKind.androidRecognizer => Icons.android,
      VoiceControlRowKind.microphonePermission =>
        Icons.mic_external_on_outlined,
      VoiceControlRowKind.gatewayProfileStt => Icons.cloud_outlined,
      VoiceControlRowKind.commandWord => Icons.short_text,
      VoiceControlRowKind.howItWorks => Icons.record_voice_over,
      VoiceControlRowKind.trustServer => Icons.verified_user_outlined,
    };
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
        GoRouter.maybeOf(context)?.go(AppRoutes.settings);
      },
      VoiceControlActionKind.trustServer => () {
        Navigator.of(context).pop();
        onTrustServer?.call();
      },
    };
  }
}
