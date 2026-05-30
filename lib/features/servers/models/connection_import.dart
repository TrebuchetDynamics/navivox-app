// Models for Navivox connection import/pairing handoff payloads.
//
// These value types are shared across the registration, pairing, setup,
// and screens subfolders.

enum PairingHandoffSource { manual, qrImage, sharedText, directAppOpen }

class SetupQrImageImport {
  const SetupQrImageImport({
    this.baseUrl,
    this.token,
    this.webSocketUrl,
    this.serverId,
    this.profileId,
    this.source = PairingHandoffSource.manual,
  });

  final String? baseUrl;
  final String? token;
  final String? webSocketUrl;
  final String? serverId;
  final String? profileId;
  final PairingHandoffSource source;

  bool get hasValues => baseUrl != null || token != null;

  SetupQrImageImport withSource(PairingHandoffSource source) {
    return SetupQrImageImport(
      baseUrl: baseUrl,
      token: token,
      webSocketUrl: webSocketUrl,
      serverId: serverId,
      profileId: profileId,
      source: source,
    );
  }
}
