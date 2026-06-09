// Models for Navivox connection import/pairing handoff payloads.
//
// These value types are shared across the registration, pairing, setup,
// and screens subfolders.

enum PairingHandoffSource { manual, qrImage, sharedText, directAppOpen }

class PairingHandoffSetupIntent {
  const PairingHandoffSetupIntent({this.entryScreen, this.sections = const []});

  final String? entryScreen;
  final List<String> sections;

  bool get suggestsConfig {
    final entry = entryScreen?.trim().toLowerCase();
    if (entry != null && entry.startsWith('setup.')) return true;
    return sections.any(_setupSectionSuggestsConfig);
  }
}

bool _setupSectionSuggestsConfig(String section) {
  return switch (section.trim().toLowerCase()) {
    'provider' || 'model' || 'workspace' || 'channels' || 'config' => true,
    _ => false,
  };
}

class SetupQrImageImport {
  const SetupQrImageImport({
    this.baseUrl,
    this.token,
    this.webSocketUrl,
    this.serverId,
    this.profileId,
    this.source = PairingHandoffSource.manual,
    this.setupIntent = const PairingHandoffSetupIntent(),
  });

  final String? baseUrl;
  final String? token;
  final String? webSocketUrl;
  final String? serverId;
  final String? profileId;
  final PairingHandoffSource source;
  final PairingHandoffSetupIntent setupIntent;

  bool get hasValues => baseUrl != null || token != null;

  SetupQrImageImport withSource(PairingHandoffSource source) {
    return SetupQrImageImport(
      baseUrl: baseUrl,
      token: token,
      webSocketUrl: webSocketUrl,
      serverId: serverId,
      profileId: profileId,
      source: source,
      setupIntent: setupIntent,
    );
  }
}
