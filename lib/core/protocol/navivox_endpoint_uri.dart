/// URI normalization helpers shared by Navivox pairing and setup flows.
String navivoxOriginFromUri(Uri uri) {
  final host = uri.host.contains(':') ? '[${uri.host}]' : uri.host;
  final port = uri.hasPort ? ':${uri.port}' : '';
  return '${uri.scheme}://$host$port';
}

String navivoxHttpBaseUrlFromEndpointUri(Uri uri, {String? descriptor}) {
  final scheme = switch (uri.scheme.toLowerCase()) {
    'ws' => 'http',
    'wss' => 'https',
    'http' => 'http',
    'https' => 'https',
    _ => throw FormatException(
      'Navivox endpoint URI must use ws, wss, http, or https',
      descriptor,
    ),
  };
  if (uri.host.isEmpty) {
    throw FormatException(
      'Navivox endpoint URI must include a host',
      descriptor,
    );
  }
  return navivoxOriginFromUri(uri.replace(scheme: scheme));
}
