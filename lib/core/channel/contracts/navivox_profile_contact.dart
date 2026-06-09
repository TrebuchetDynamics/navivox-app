import '../../protocol/navivox_profile_contact_key.dart';
import '../../protocol/voice_unavailable_reason.dart';

class NavivoxProfileContact {
  const NavivoxProfileContact({
    required this.serverId,
    required this.profileId,
    required this.displayName,
    required this.serverLabel,
    required this.health,
    required this.latestPreview,
    this.latestPreviewKind = 'status',
    this.latestAt,
    this.workspaceRootCount = 0,
    this.workspaceRootsOk = true,
    this.workspaceRootsWarning = 0,
    this.workspaceRootsError = 0,
    this.attentionBadges = const [],
    this.micAvailable = false,
    this.voiceCapability = const NavivoxVoiceCapability(),
    this.activeTurnState = 'idle',
    String? avatarSeed,
  }) : avatarSeed = avatarSeed ?? '$serverId:$profileId';

  final String serverId;
  final String profileId;
  final String displayName;
  final String serverLabel;
  final NavivoxProfileHealth health;
  final String latestPreview;
  final String latestPreviewKind;
  final DateTime? latestAt;
  final int workspaceRootCount;
  final bool workspaceRootsOk;
  final int workspaceRootsWarning;
  final int workspaceRootsError;
  final List<String> attentionBadges;
  final bool micAvailable;
  final NavivoxVoiceCapability voiceCapability;
  final String activeTurnState;
  final String avatarSeed;

  String get key =>
      navivoxProfileContactKey(serverId: serverId, profileId: profileId);
}

enum NavivoxProfileHealth { online, offline, needsAuth, warning }

NavivoxProfileHealth navivoxProfileHealthFromJson(Object? value) {
  return switch (value?.toString().trim().toLowerCase()) {
    'offline' => NavivoxProfileHealth.offline,
    'needs_auth' ||
    'needs-auth' ||
    'needsauth' => NavivoxProfileHealth.needsAuth,
    'warning' => NavivoxProfileHealth.warning,
    _ => NavivoxProfileHealth.online,
  };
}

class NavivoxVoiceCapability {
  const NavivoxVoiceCapability({
    this.deviceStt = 'unavailable',
    this.serverStt = 'unavailable',
    this.serverTts = 'unavailable',
    this.disabledReason = '',
    this.recoveryAction = '',
    this.isReported = false,
  });

  final String deviceStt;
  final String serverStt;
  final String serverTts;
  final String disabledReason;
  final String recoveryAction;
  final bool isReported;

  bool get enabled => captureUnavailableReason == null;

  String? get captureUnavailableReason {
    final reason = disabledReason.trim();
    if (reason.isNotEmpty) return canonicalVoiceUnavailableReason(reason);
    if (blocksDeviceCapture) return deviceSttUnavailableReason;
    return null;
  }

  bool get blocksDeviceCapture => disabledReason.trim().isNotEmpty;
}

class NavivoxProfileRoutingSelection {
  const NavivoxProfileRoutingSelection({
    this.workspace,
    this.provider,
    this.channel,
  });

  final String? workspace;
  final String? provider;
  final String? channel;
}
