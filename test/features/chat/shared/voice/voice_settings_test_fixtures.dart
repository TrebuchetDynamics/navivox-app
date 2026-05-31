import 'package:navivox/shared/voice/voice_settings.dart';

/// Shared trusted continuous-voice settings used by chat presentation tests.
NavivoxVoiceSettings trustedVoiceSettingsFor(String serverId) {
  return NavivoxVoiceSettings(trustedServerIds: {serverId});
}

/// Shared untrusted continuous-voice settings used when trust actions are tested.
const untrustedVoiceSettings = NavivoxVoiceSettings();
