import 'package:navivox/shared/voice/voice_settings.dart';

import '../profiles/profile_scope_test_contracts.dart';

/// Shared trusted continuous-voice settings used by chat presentation tests.
NavivoxVoiceSettings trustedVoiceSettingsFor(String serverId) {
  return NavivoxVoiceSettings(trustedServerIds: {serverId});
}

/// Shared trusted continuous-voice settings routed through a Profile scope.
NavivoxVoiceSettings trustedVoiceSettingsForScope(ChatProfileScope scope) {
  return trustedVoiceSettingsFor(scope.serverId);
}

/// Shared untrusted continuous-voice settings used when trust actions are tested.
const untrustedVoiceSettings = NavivoxVoiceSettings();
