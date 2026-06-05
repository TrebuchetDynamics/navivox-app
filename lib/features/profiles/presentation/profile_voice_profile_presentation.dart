import '../../../core/gateway/navivox_gateway_protocol.dart';
import '../../../core/protocol/navivox_json.dart';

final class ProfileVoiceProfilePresentation {
  const ProfileVoiceProfilePresentation();

  String get title => 'Voice profile';
  String get textFallbackNotice =>
      'Text chat remains available when voice providers are unavailable.';
  String get selectProfileMessage =>
      'Select a profile to inspect voice settings.';
  String get unavailableMessage => 'Gormes voice profiles are unavailable.';
  String get noProfileMessage => 'No voice profile reported by Gormes.';
  String get editActionLabel => 'Edit voice profile';
  String get loadEvidenceActionLabel => 'Load voice fallback evidence';
  String get applyActionLabel => 'Validate and apply through Gormes';
  String get cancelActionLabel => 'Cancel';

  String profileLine(NavivoxVoiceProfileView view) =>
      'Profile: ${view.displayName}';

  String availableSttLine(NavivoxVoiceProviderMatrix providerMatrix) =>
      'Available STT: ${listLabel(providerMatrix.sttProviders)}';

  String availableTtsLine(NavivoxVoiceProviderMatrix providerMatrix) =>
      'Available TTS: ${listLabel(providerMatrix.ttsProviders)}';

  String sttProviderLine(NavivoxProfileVoiceProfile voiceProfile) =>
      'STT provider: ${valueOrUnset(voiceProfile.sttProvider)}';

  String ttsProviderLine(NavivoxProfileVoiceProfile voiceProfile) =>
      'TTS provider: ${valueOrUnset(voiceProfile.ttsProvider)}';

  String voiceIdLine(NavivoxProfileVoiceProfile voiceProfile) =>
      'Voice ID: ${valueOrUnset(voiceProfile.voiceId)}';

  String languagePolicyLine(NavivoxProfileVoiceProfile voiceProfile) =>
      'Language policy: ${valueOrUnset(voiceProfile.languagePolicy)}';

  String fallbackVoiceLine(NavivoxProfileVoiceProfile voiceProfile) =>
      'Fallback voice: ${valueOrUnset(voiceProfile.fallbackVoice)}';

  String sttCredentialLine(NavivoxVoiceCredentialStatus? status) =>
      credentialLabel('STT credential', status);

  String ttsCredentialLine(NavivoxVoiceCredentialStatus? status) =>
      credentialLabel('TTS credential', status);

  String credentialLabel(String label, NavivoxVoiceCredentialStatus? status) {
    if (status == null) return '$label: not reported';
    final suffix = status.source.trim().isEmpty ? '' : ' (${status.source})';
    return '$label: ${status.status}$suffix';
  }

  String validationErrorLine(NavivoxVoiceProfileFieldError error) {
    return '${error.field}: ${error.message}';
  }

  String listLabel(List<String> values) {
    if (values.isEmpty) return 'not reported';
    return values.join(', ');
  }

  String valueOrUnset(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? 'unset' : trimmed;
  }

  VoiceRunEvidencePresentation evidenceFor(NavivoxRunRecordSnapshot record) {
    final voice = navivoxMapFieldFromJson(record.raw, 'voice');
    final serverStt = navivoxMapFieldFromJson(voice, 'server_stt');
    final tts = navivoxMapFieldFromJson(voice, 'tts');
    return VoiceRunEvidencePresentation(
      serverSttLine: 'Server STT: ${providerStatus(serverStt)}',
      ttsLine: 'TTS: ${providerStatus(tts)}',
    );
  }

  String providerStatus(Map<String, Object?> value) {
    final provider = navivoxStringFieldFromJson(value, 'provider');
    final status = navivoxStringFieldFromJson(value, 'status');
    return [provider, status].where((part) => part.isNotEmpty).join(' ');
  }
}

final class VoiceRunEvidencePresentation {
  const VoiceRunEvidencePresentation({
    required this.serverSttLine,
    required this.ttsLine,
  });

  final String serverSttLine;
  final String ttsLine;
}
