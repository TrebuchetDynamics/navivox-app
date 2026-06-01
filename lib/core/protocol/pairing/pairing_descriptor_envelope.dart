/// Parsed outer URI contract for a `navivox://connect` pairing descriptor.
///
/// The descriptor envelope is intentionally closed: all connection state must
/// live in explicit query fields so it can be replayed, validated, and tested.
class PairingDescriptorEnvelope {
  const PairingDescriptorEnvelope._(this.uri);

  factory PairingDescriptorEnvelope.parse(String descriptor) {
    final uri = Uri.parse(descriptor.trim());
    if (uri.scheme != 'navivox' || uri.host != 'connect') {
      throw FormatException(
        'Expected navivox://connect descriptor',
        descriptor,
      );
    }
    if (uri.path.isNotEmpty || uri.hasFragment) {
      throw FormatException(
        'Pairing descriptor must not include path or fragment state',
        descriptor,
      );
    }
    if (uri.userInfo.isNotEmpty) {
      throw FormatException(
        'Pairing descriptor must not include userinfo',
        descriptor,
      );
    }
    return PairingDescriptorEnvelope._(uri);
  }

  final Uri uri;

  Map<String, List<String>> get queryParametersAll => uri.queryParametersAll;

  String get rawQuery => uri.query;
}
