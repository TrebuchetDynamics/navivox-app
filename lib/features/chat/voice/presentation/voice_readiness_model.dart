enum VoiceReadinessStatus { ready, checking, blocked }

enum VoiceReadinessBlockerKind {
  disabledInSettings,
  selectProfileContact,
  trustGateway,
  deviceSpeechUnavailable,
  microphonePermissionDenied,
  gatewayProfileSttUnavailable,
  profileContactNotOnline,
  profileMicUnavailable,
}
