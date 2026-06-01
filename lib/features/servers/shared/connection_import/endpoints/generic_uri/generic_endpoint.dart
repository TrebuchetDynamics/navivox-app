part of '../../parser.dart';

Map<String, String> _genericUriFields(
  Uri uri, {
  required _ConnectionImportEndpointUriIdentity identity,
}) {
  final fields = _uriQueryFields(uri);
  if (identity.isWebSocket &&
      navivoxFirstStringFieldFromJson(fields, _webSocketUrlFieldNames) ==
          null) {
    fields['websocket_url'] = uri.toString();
  }
  return fields;
}

Map<String, String> _uriQueryFields(Uri uri) =>
    navivoxFirstNonBlankQueryParameterValues(uri.queryParametersAll);

enum _GenericEndpointSchemeKind { http, webSocket, unsupported }

bool _hasGenericEndpointIdentity(Uri uri) =>
    uri.hasScheme && uri.host.isNotEmpty && _hasValidExplicitPort(uri);

bool _hasValidExplicitPort(Uri uri) {
  if (!uri.hasPort) return true;
  try {
    final port = uri.port;
    return port > 0 && port <= 65535;
  } on FormatException {
    return false;
  }
}

String? _webSocketUriBaseUrl(Uri uri) {
  try {
    return navivoxHttpBaseUrlFromEndpointUri(uri);
  } on FormatException {
    return null;
  }
}
