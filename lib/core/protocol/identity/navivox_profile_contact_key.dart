/// Builds the stable key used to identify a profile contact across channel,
/// routing, and transcript state.
String navivoxProfileContactKey({
  required String serverId,
  required String profileId,
}) {
  return '$serverId::$profileId';
}

/// Builds a profile-contact key from optional wire values.
///
/// Returns null when either side is absent or blank after trimming.
String? navivoxProfileContactKeyFromNullable({
  required String? serverId,
  required String? profileId,
}) {
  final server = serverId?.trim();
  final profile = profileId?.trim();
  if (server == null || server.isEmpty || profile == null || profile.isEmpty) {
    return null;
  }
  return navivoxProfileContactKey(serverId: server, profileId: profile);
}
