import '../../core/channel/navivox_channel.dart';
import 'count_labels.dart';
import 'profile_health_labels.dart';

String profileContactDisplayLabel(
  NavivoxProfileContact? contact, {
  required String fallback,
}) {
  final displayName = contact?.displayName.trim();
  if (displayName != null && displayName.isNotEmpty) return displayName;
  return fallback;
}

String profileContactServerLabel(
  NavivoxProfileContact? contact, {
  required String fallback,
}) {
  final label = contact?.serverLabel.trim();
  if (label != null && label.isNotEmpty) return label;
  return fallback;
}

String profileContactIdentityLabel(
  NavivoxProfileContact contact, {
  required String fallback,
}) {
  final displayName = contact.displayName.trim();
  if (displayName.isNotEmpty) return displayName;
  final profileId = contact.profileId.trim();
  if (profileId.isNotEmpty) return profileId;
  final serverId = contact.serverId.trim();
  if (serverId.isNotEmpty) return serverId;
  return fallback;
}

List<String> profileContactProjectStatusSegments(
  NavivoxProfileContact profile,
) {
  final segments = <String>[];
  if (profile.workspaceRootCount > 0) {
    segments.add(countLabel(profile.workspaceRootCount, 'project'));
  }
  if (profile.workspaceRootsError > 0) {
    segments.add(countLabel(profile.workspaceRootsError, 'error'));
  }
  if (profile.workspaceRootsWarning > 0) {
    segments.add(countLabel(profile.workspaceRootsWarning, 'warning'));
  }
  if (segments.isEmpty && !profile.workspaceRootsOk) {
    segments.add('project attention needed');
  }
  return segments;
}

String profileContactProjectStatusLabel(NavivoxProfileContact profile) {
  return profileContactProjectStatusSegments(profile).join(' • ');
}

String profileContactStatusBarLabel(NavivoxProfileContact profile) {
  return [
    profile.serverLabel,
    profileHealthLabel(profile.health),
    ...profileContactProjectStatusSegments(profile),
  ].join(' • ');
}

String profileContactWorkspaceLabel(NavivoxProfileContact contact) {
  if (!contact.workspaceRootsOk) return 'workspace issue';
  if (contact.workspaceRootCount == 1) return '1 root';
  return '${contact.workspaceRootCount} roots';
}

String profileContactVoiceLabel(NavivoxProfileContact contact) {
  if (!contact.micAvailable) return 'mic unavailable';
  return 'mic available';
}

String profileContactChannelsLabel(NavivoxProfileContact contact) {
  return contact.micAvailable ? 'local/web chat, voice' : 'local/web chat';
}

String profileContactMemoryLabel(NavivoxProfileContact contact) {
  if (!contact.workspaceRootsOk) return 'Goncho needs workspace attention';
  return 'Goncho available';
}

String profileContactGonchoStatusLabel(NavivoxProfileContact contact) {
  if (!contact.workspaceRootsOk) return 'needs workspace attention';
  if (contact.workspaceRootCount > 0) return 'available';
  return 'not reported by API';
}

String profileContactLatestLabel(NavivoxProfileContact contact) {
  if (contact.activeTurnState == 'streaming') return 'typing…';
  final preview = contact.latestPreview.trim();
  return preview.isEmpty ? 'no recent activity' : preview;
}

String profileContactChatListPreviewLabel(NavivoxProfileContact contact) {
  final lead = _profileContactChatListLeadLabel(contact);
  final segments = <String>[lead];
  final health = profileHealthLabel(contact.health);
  if (health != lead) segments.add(health);
  if (contact.workspaceRootsOk) {
    segments.add(profileContactWorkspaceLabel(contact));
  } else if (lead != '⚠ Workspace issue') {
    segments.add('⚠ Workspace issue');
  }
  return segments.join(' · ');
}

String _profileContactChatListLeadLabel(NavivoxProfileContact contact) {
  if (contact.activeTurnState == 'streaming') return 'typing…';
  final preview = contact.latestPreview.trim();
  if (preview.isNotEmpty) return preview;
  if (!contact.workspaceRootsOk) return '⚠ Workspace issue';
  return 'Profile ready';
}

List<String> profileContactAgentFallbackSummaryLines(
  NavivoxProfileContact contact,
) {
  final lines = [
    contact.profileId,
    'Status: ${profileHealthLabel(contact.health)}',
    'Channels: ${profileContactChannelsLabel(contact)}',
    'Memory: ${profileContactMemoryLabel(contact)}',
    'Skills: profile skills pending API',
    'Config: profile scoped',
  ];
  final latestPreview = contact.latestPreview.trim();
  if (latestPreview.isNotEmpty) lines.add('Latest: $latestPreview');
  return lines;
}

List<String> profileContactSearchTerms(NavivoxProfileContact contact) {
  return [
    contact.displayName,
    contact.profileId,
    contact.serverId,
    contact.serverLabel,
    contact.latestPreview,
    profileHealthLabel(contact.health),
    compactProfileHealthLabel(contact.health),
    profileContactWorkspaceLabel(contact),
    profileContactVoiceLabel(contact),
    profileContactLatestLabel(contact),
    profileContactChatListPreviewLabel(contact),
    contact.activeTurnState,
    ...contact.attentionBadges,
  ];
}
