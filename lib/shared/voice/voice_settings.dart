class NavivoxVoiceSettings {
  const NavivoxVoiceSettings({
    this.continuousVoiceEnabled = true,
    this.profileSwitchingEnabled = true,
    this.commandWord = 'navi',
    this.trustedServerIds = const {},
  });

  final bool continuousVoiceEnabled;
  final bool profileSwitchingEnabled;
  final String commandWord;
  final Set<String> trustedServerIds;

  bool isTrusted(String serverId) => trustedServerIds.contains(serverId);

  NavivoxVoiceSettings copyWith({
    bool? continuousVoiceEnabled,
    bool? profileSwitchingEnabled,
    String? commandWord,
    Set<String>? trustedServerIds,
  }) {
    return NavivoxVoiceSettings(
      continuousVoiceEnabled:
          continuousVoiceEnabled ?? this.continuousVoiceEnabled,
      profileSwitchingEnabled:
          profileSwitchingEnabled ?? this.profileSwitchingEnabled,
      commandWord: commandWord ?? this.commandWord,
      trustedServerIds: trustedServerIds ?? this.trustedServerIds,
    );
  }
}
