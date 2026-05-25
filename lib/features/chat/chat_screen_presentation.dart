import '../../core/channel/navivox_channel.dart';
import '../../core/protocol/navivox_event.dart';
import '../../core/protocol/navivox_voice_run.dart';
import '../settings/providers/voice_settings_provider.dart';

class ChatScreenPresentation {
  const ChatScreenPresentation({
    required this.activeServer,
    required this.activeProfile,
    required this.selectedAgent,
    required this.appBarTitle,
    required this.appBarSubtitle,
    required this.infoRows,
    required this.voiceMode,
    required this.transcriptMessages,
    required this.pendingVoiceRun,
    required this.assistantTypingLabel,
    required this.forwardTargets,
  });

  factory ChatScreenPresentation.fromState({
    required NavivoxChannelState state,
    required NavivoxVoiceSettings voiceSettings,
    required bool localVoiceCaptureAvailable,
    String? runtimeVoiceDisabledReason,
    String? notice,
    bool commandMode = false,
  }) {
    final activeServer = state.activeServer;
    final activeProfile = state.activeProfileContact;
    final selectedAgent = state.selectedAgentId == null
        ? null
        : state.agents
              .where((agent) => agent.id == state.selectedAgentId)
              .firstOrNull;
    final pendingVoiceRun =
        state.activeVoiceRun?.status == NavivoxVoiceRunStatus.pendingSend
        ? state.activeVoiceRun
        : null;
    final voiceDisabledReason = _voiceDisabledReason(
      localVoiceCaptureAvailable: localVoiceCaptureAvailable,
      activeProfile: activeProfile,
      settings: voiceSettings,
      runtimeVoiceDisabledReason: runtimeVoiceDisabledReason,
    );
    final voiceRecoveryAction = _voiceRecoveryAction(
      activeProfile,
      voiceDisabledReason,
    );
    final transcriptMessages = [
      ...state.messagesList,
      if (pendingVoiceRun != null) _pendingVoiceMessage(pendingVoiceRun),
    ];

    return ChatScreenPresentation(
      activeServer: activeServer,
      activeProfile: activeProfile,
      selectedAgent: selectedAgent,
      appBarTitle: activeProfile?.displayName ?? activeServer?.name ?? 'Chats',
      appBarSubtitle: activeProfile != null
          ? _profileStatusBar(activeProfile)
          : activeServer?.status,
      infoRows: _infoRows(
        profile: activeProfile,
        server: activeServer,
        agent: selectedAgent,
      ),
      voiceMode: VoiceModePresentation(
        commandMode: commandMode,
        commandWord: voiceSettings.commandWord,
        disabledReason: voiceDisabledReason,
        notice: notice,
        pending: pendingVoiceRun != null,
        pendingTranscript: pendingVoiceRun?.transcript,
        profileName: activeProfile?.displayName,
        recoveryAction: voiceRecoveryAction,
        localVoiceCaptureAvailable: localVoiceCaptureAvailable,
        ready:
            localVoiceCaptureAvailable &&
            activeProfile != null &&
            voiceDisabledReason == null,
        canTrustServer:
            activeProfile != null &&
            voiceDisabledReason == 'trust ${activeProfile.serverLabel}',
      ),
      transcriptMessages: transcriptMessages,
      pendingVoiceRun: pendingVoiceRun,
      assistantTypingLabel: activeProfile?.activeTurnState == 'streaming'
          ? '${activeProfile!.displayName} is typing…'
          : null,
      forwardTargets: state.profileContacts
          .where((contact) => contact.key != activeProfile?.key)
          .toList(growable: false),
    );
  }

  final NavivoxServer? activeServer;
  final NavivoxProfileContact? activeProfile;
  final NavivoxAgent? selectedAgent;
  final String appBarTitle;
  final String? appBarSubtitle;
  final List<ChatInfoRowPresentation> infoRows;
  final VoiceModePresentation voiceMode;
  final List<NavivoxChatMessage> transcriptMessages;
  final NavivoxVoiceRun? pendingVoiceRun;
  final String? assistantTypingLabel;
  final List<NavivoxProfileContact> forwardTargets;

  String get chatInfoTooltip => 'Chat info';

  String get chatInfoTitle => 'Chat info';

  static String profileHealthLabel(NavivoxProfileHealth health) {
    return switch (health) {
      NavivoxProfileHealth.online => 'online',
      NavivoxProfileHealth.offline => 'offline',
      NavivoxProfileHealth.needsAuth => 'auth required',
      NavivoxProfileHealth.warning => 'warning',
    };
  }

  static String _profileStatusBar(NavivoxProfileContact profile) {
    return [
      profile.serverLabel,
      profileHealthLabel(profile.health),
      ..._projectStatusSegments(profile),
    ].join(' • ');
  }

  static List<String> _projectStatusSegments(NavivoxProfileContact profile) {
    final segments = <String>[];
    if (profile.workspaceRootCount > 0) {
      segments.add(
        '${profile.workspaceRootCount} ${_plural(profile.workspaceRootCount, 'project', 'projects')}',
      );
    }
    if (profile.workspaceRootsError > 0) {
      segments.add(
        '${profile.workspaceRootsError} ${_plural(profile.workspaceRootsError, 'error', 'errors')}',
      );
    }
    if (profile.workspaceRootsWarning > 0) {
      segments.add(
        '${profile.workspaceRootsWarning} ${_plural(profile.workspaceRootsWarning, 'warning', 'warnings')}',
      );
    }
    if (segments.isEmpty && !profile.workspaceRootsOk) {
      segments.add('project attention needed');
    }
    return segments;
  }

  static String _projectStatusLabel(NavivoxProfileContact profile) {
    return _projectStatusSegments(profile).join(' • ');
  }

  static String _plural(int count, String one, String many) {
    return count == 1 ? one : many;
  }

  static String? _voiceDisabledReason({
    required bool localVoiceCaptureAvailable,
    required NavivoxProfileContact? activeProfile,
    required NavivoxVoiceSettings settings,
    required String? runtimeVoiceDisabledReason,
  }) {
    if (!settings.continuousVoiceEnabled) return 'disabled in Settings';
    if (activeProfile == null) return 'select a profile contact';
    if (!localVoiceCaptureAvailable) return 'device STT unavailable';
    if (runtimeVoiceDisabledReason != null) return runtimeVoiceDisabledReason;
    final profileVoiceReason =
        activeProfile.voiceCapability.captureUnavailableReason;
    if (profileVoiceReason != null) return profileVoiceReason;
    if (!settings.isTrusted(activeProfile.serverId)) {
      return 'trust ${activeProfile.serverLabel}';
    }
    if (activeProfile.health != NavivoxProfileHealth.online) {
      return profileHealthLabel(activeProfile.health);
    }
    if (!activeProfile.micAvailable) return 'mic unavailable';
    return null;
  }

  static String? _voiceRecoveryAction(
    NavivoxProfileContact? activeProfile,
    String? voiceDisabledReason,
  ) {
    if (voiceDisabledReason == null) return null;
    final capability = activeProfile?.voiceCapability;
    final recoveryAction = capability?.recoveryAction.trim();
    if (capability != null &&
        recoveryAction != null &&
        recoveryAction.isNotEmpty &&
        (voiceDisabledReason == capability.captureUnavailableReason ||
            voiceDisabledReason == 'device STT unavailable')) {
      return recoveryAction;
    }
    if (voiceDisabledReason == 'device STT unavailable') {
      return 'Install or enable device speech recognition, then reopen Navivox.';
    }
    if (voiceDisabledReason == 'microphone permission denied') {
      return 'Grant microphone permission in Android App info, then reopen Navivox.';
    }
    return null;
  }

  static NavivoxChatMessage _pendingVoiceMessage(NavivoxVoiceRun run) {
    return NavivoxChatMessage(
      id: 'pending-${run.id}',
      author: NavivoxMessageAuthor.user,
      kind: NavivoxMessageKind.voice,
      createdAt: run.createdAt,
      voice: NavivoxVoiceMessage(
        voiceRunId: run.id,
        duration: run.duration ?? Duration.zero,
        transcript: run.transcript ?? '',
        confidence: run.confidence ?? 1,
        status: run.status,
      ),
    );
  }

  static List<ChatInfoRowPresentation> _infoRows({
    required NavivoxProfileContact? profile,
    required NavivoxServer? server,
    required NavivoxAgent? agent,
  }) {
    final rows = <ChatInfoRowPresentation>[];
    if (profile != null) {
      rows.addAll([
        ChatInfoRowPresentation(
          kind: ChatInfoRowKind.profile,
          label: 'Profile',
          value: profile.displayName,
        ),
        ChatInfoRowPresentation(
          kind: ChatInfoRowKind.profileId,
          label: 'Profile ID',
          value: profile.profileId,
        ),
        ChatInfoRowPresentation(
          kind: ChatInfoRowKind.server,
          label: 'Server',
          value: profile.serverLabel,
        ),
        if (profile.serverId.trim() != profile.serverLabel.trim())
          ChatInfoRowPresentation(
            kind: ChatInfoRowKind.serverId,
            label: 'Server ID',
            value: profile.serverId,
          ),
        ChatInfoRowPresentation(
          kind: ChatInfoRowKind.status,
          label: 'Status',
          value: profileHealthLabel(profile.health),
        ),
        if (_projectStatusSegments(profile).isNotEmpty)
          ChatInfoRowPresentation(
            kind: ChatInfoRowKind.projects,
            label: 'Projects',
            value: _projectStatusLabel(profile),
          ),
      ]);
    } else if (server != null) {
      rows.addAll([
        ChatInfoRowPresentation(
          kind: ChatInfoRowKind.server,
          label: 'Server',
          value: server.name,
        ),
        ChatInfoRowPresentation(
          kind: ChatInfoRowKind.status,
          label: 'Status',
          value: server.status,
        ),
      ]);
    } else {
      rows.add(
        const ChatInfoRowPresentation(
          kind: ChatInfoRowKind.selectProfile,
          label: 'Profile',
          value: 'Select a chat',
        ),
      );
    }
    if (agent != null) {
      rows.add(
        ChatInfoRowPresentation(
          kind: ChatInfoRowKind.agent,
          label: 'Agent',
          value: agent.name,
        ),
      );
    }
    return rows;
  }
}

enum ChatInfoRowKind {
  profile,
  profileId,
  server,
  serverId,
  status,
  projects,
  agent,
  selectProfile,
}

class ChatInfoRowPresentation {
  const ChatInfoRowPresentation({
    required this.kind,
    required this.label,
    required this.value,
  });

  final ChatInfoRowKind kind;
  final String label;
  final String value;
}

class VoiceModePresentation {
  const VoiceModePresentation({
    required this.commandMode,
    required this.commandWord,
    required this.disabledReason,
    required this.notice,
    required this.pending,
    required this.pendingTranscript,
    required this.profileName,
    required this.recoveryAction,
    required this.localVoiceCaptureAvailable,
    required this.ready,
    required this.canTrustServer,
  });

  final bool commandMode;
  final String commandWord;
  final String? disabledReason;
  final String? notice;
  final bool pending;
  final String? pendingTranscript;
  final String? profileName;
  final String? recoveryAction;
  final bool localVoiceCaptureAvailable;
  final bool ready;
  final bool canTrustServer;

  String get controlsSemanticsHint => 'Open continuous voice controls';

  String get sheetTitle => 'Continuous voice';

  String get cancelPendingButtonLabel => 'Cancel';

  String get trustServerButtonLabel => 'Trust server';

  List<VoiceControlRowPresentation> get sheetRows {
    final rows = <VoiceControlRowPresentation>[
      VoiceControlRowPresentation(
        kind: VoiceControlRowKind.status,
        title: sheetStatus,
        subtitle: sheetSubtitle,
      ),
    ];
    if (pending) {
      rows.add(
        const VoiceControlRowPresentation(
          kind: VoiceControlRowKind.cancelPending,
          title: 'Cancel pending voice',
          action: VoiceControlActionKind.cancelPending,
        ),
      );
    }
    if (disabledReason != null && recoveryAction != null) {
      rows.add(
        VoiceControlRowPresentation(
          kind: VoiceControlRowKind.recoveryAction,
          title: 'Recovery action',
          subtitle: recoveryAction,
        ),
      );
    }
    if (disabledReason != null) {
      rows.add(
        VoiceControlRowPresentation(
          kind: VoiceControlRowKind.openVoiceSettings,
          title: 'Open voice settings',
          subtitle: voiceSettingsSubtitle,
          action: VoiceControlActionKind.openVoiceSettings,
        ),
      );
    }
    if (showSttDiagnostics) {
      rows.addAll([
        const VoiceControlRowPresentation(
          kind: VoiceControlRowKind.diagnostics,
          title: 'Voice diagnostics',
          subtitle:
              'Android recognizer, microphone permission, and gateway profile STT are separate checks.',
        ),
        VoiceControlRowPresentation(
          kind: VoiceControlRowKind.androidRecognizer,
          title: 'Android recognizer',
          subtitle: androidRecognizerStatus,
        ),
        VoiceControlRowPresentation(
          kind: VoiceControlRowKind.microphonePermission,
          title: 'Microphone permission',
          subtitle: microphonePermissionStatus,
        ),
        VoiceControlRowPresentation(
          kind: VoiceControlRowKind.gatewayProfileStt,
          title: 'Gateway profile STT',
          subtitle: gatewayProfileSttStatus,
        ),
      ]);
    }
    rows.addAll([
      VoiceControlRowPresentation(
        kind: VoiceControlRowKind.commandWord,
        title: 'Command word',
        subtitle: commandWord,
      ),
      VoiceControlRowPresentation(
        kind: VoiceControlRowKind.howItWorks,
        title: 'How it works',
        subtitle: howItWorks,
      ),
    ]);
    if (!pending && canTrustServer) {
      rows.add(
        const VoiceControlRowPresentation(
          kind: VoiceControlRowKind.trustServer,
          title: 'Trust server',
          action: VoiceControlActionKind.trustServer,
        ),
      );
    }
    return List.unmodifiable(rows);
  }

  String? get bannerText {
    if (pending) return 'Sending...';
    if (commandMode) return 'Command mode';
    if (disabledReason != null) {
      return 'Continuous voice unavailable: $disabledReason';
    }
    if (ready) return 'Continuous voice ready';
    return notice;
  }

  String get sheetStatus {
    if (pending) return 'Pending voice turn';
    if (disabledReason != null) return 'Continuous voice unavailable';
    if (ready) return 'Ready for ${profileName ?? 'chat'}';
    return 'Voice standby';
  }

  String get voiceSettingsSubtitle {
    return disabledReason == 'device STT unavailable'
        ? 'Review continuous voice after enabling device speech recognition.'
        : disabledReason == 'microphone permission denied'
        ? 'Review continuous voice after granting microphone permission.'
        : disabledReason == 'select a profile contact'
        ? 'Select a profile contact before reviewing continuous voice settings.'
        : 'Review continuous voice and trust settings';
  }

  bool get showSttDiagnostics {
    return disabledReason == 'device STT unavailable' ||
        disabledReason == 'microphone permission denied';
  }

  String get sheetSubtitle {
    final pendingText = pendingTranscript;
    if (pendingText != null && pendingText.isNotEmpty) return pendingText;
    return disabledReason ??
        'Tap the mic to speak. Say “$commandWord” for command mode.';
  }

  String get androidRecognizerStatus {
    return localVoiceCaptureAvailable
        ? 'Ready in Navivox; gateway STT status is separate.'
        : 'No local speech recognizer is active in Navivox.';
  }

  String get microphonePermissionStatus {
    return disabledReason == 'microphone permission denied'
        ? 'Denied by Android. Grant microphone permission in App info.'
        : 'Not denied by Android in this session; checked when capture starts.';
  }

  String get gatewayProfileSttStatus {
    return disabledReason == 'device STT unavailable'
        ? 'Gateway reported device STT unavailable for this profile.'
        : 'Gateway profile STT is not the current blocker.';
  }

  String get howItWorks {
    return disabledReason == null
        ? 'Tap once to capture a turn. Use command mode for local actions like switching profiles, stop, cancel, help, or settings.'
        : 'Reason: $disabledReason. Continuous voice stays off until resolved.';
  }
}

enum VoiceControlRowKind {
  status,
  cancelPending,
  recoveryAction,
  openVoiceSettings,
  diagnostics,
  androidRecognizer,
  microphonePermission,
  gatewayProfileStt,
  commandWord,
  howItWorks,
  trustServer,
}

enum VoiceControlActionKind {
  none,
  cancelPending,
  openVoiceSettings,
  trustServer,
}

class VoiceControlRowPresentation {
  const VoiceControlRowPresentation({
    required this.kind,
    required this.title,
    this.subtitle,
    this.action = VoiceControlActionKind.none,
  });

  final VoiceControlRowKind kind;
  final String title;
  final String? subtitle;
  final VoiceControlActionKind action;
}
