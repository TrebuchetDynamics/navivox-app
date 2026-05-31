import '../serialization/navivox_json.dart';

/// URI normalization helpers shared by Navivox pairing and setup flows.
const navivoxEndpointSchemes = {'http', 'https', 'ws', 'wss'};

bool navivoxIsEndpointScheme(String scheme) {
  return navivoxEndpointSchemes.contains(scheme.trim().toLowerCase());
}

String navivoxHttpSchemeFromEndpointScheme(
  String scheme, {
  String? descriptor,
}) {
  return switch (scheme.trim().toLowerCase()) {
    'ws' => 'http',
    'wss' => 'https',
    'http' => 'http',
    'https' => 'https',
    _ => throw FormatException(
      'Navivox endpoint URI must use ws, wss, http, or https',
      descriptor,
    ),
  };
}

String navivoxOriginFromUri(Uri uri) {
  return _navivoxOrigin(
    scheme: uri.scheme,
    host: uri.host,
    explicitPort: uri.hasPort ? uri.port : null,
  );
}

String _navivoxOrigin({
  required String scheme,
  required String host,
  required int? explicitPort,
}) {
  final formattedHost = host.contains(':') ? '[$host]' : host;
  final formattedPort = explicitPort == null ? '' : ':$explicitPort';
  return '$scheme://$formattedHost$formattedPort';
}

String navivoxHttpBaseUrlFromEndpointUri(Uri uri, {String? descriptor}) {
  final scheme = navivoxHttpSchemeFromEndpointScheme(
    uri.scheme,
    descriptor: descriptor,
  );
  if (uri.host.isEmpty) {
    throw FormatException(
      'Navivox endpoint URI must include a host',
      descriptor,
    );
  }
  return _navivoxOrigin(
    scheme: scheme,
    host: uri.host,
    explicitPort: uri.hasPort ? uri.port : null,
  );
}

String? navivoxHttpOriginOrOriginalFromString(String? raw) {
  final value = navivoxOptionalStringFromJson(raw);
  if (value == null) return null;
  final uri = Uri.tryParse(value);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) return value;
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') return value;
  return navivoxOriginFromUri(uri);
}

Uri navivoxWebSocketUriFromEndpointString(String raw, {String? descriptor}) {
  final uri = Uri.parse(raw);
  if (uri.host.isEmpty) {
    throw FormatException(
      'Navivox websocket URI must include a host',
      descriptor,
    );
  }
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'ws' && scheme != 'wss') {
    throw FormatException(
      'Navivox websocket URI must use ws or wss',
      descriptor,
    );
  }
  return uri;
}

String? navivoxWebSocketUrlFromEndpointString(String? raw) {
  final value = navivoxOptionalStringFromJson(raw);
  if (value == null) return null;
  try {
    return navivoxWebSocketUriFromEndpointString(value).toString();
  } on FormatException {
    return null;
  }
}

String? navivoxHttpBaseUrlFromEndpointString(String? raw) {
  final uri = _endpointUriFromString(raw);
  if (uri == null || !navivoxIsEndpointScheme(uri.scheme)) return null;
  return navivoxHttpBaseUrlFromEndpointUri(uri);
}

Uri? _endpointUriFromString(String? raw) {
  final value = navivoxOptionalStringFromJson(raw);
  if (value == null) return null;
  final uri = Uri.tryParse(value);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
  return uri;
}
