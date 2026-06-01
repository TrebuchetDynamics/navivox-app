part of '../../parser.dart';

class _ConnectionImportEndpointUriIdentity {
  const _ConnectionImportEndpointUriIdentity._({
    required this.kind,
    required this.baseUrl,
  });

  factory _ConnectionImportEndpointUriIdentity.fromUri(Uri uri) {
    if (!_hasGenericEndpointIdentity(uri)) {
      return const _ConnectionImportEndpointUriIdentity._(
        kind: _GenericEndpointSchemeKind.unsupported,
        baseUrl: null,
      );
    }

    final kind = switch (uri.scheme.toLowerCase()) {
      'http' || 'https' => _GenericEndpointSchemeKind.http,
      'ws' || 'wss' => _GenericEndpointSchemeKind.webSocket,
      _ => _GenericEndpointSchemeKind.unsupported,
    };
    return _ConnectionImportEndpointUriIdentity._(
      kind: kind,
      baseUrl: switch (kind) {
        _GenericEndpointSchemeKind.http => navivoxOriginFromUri(uri),
        _GenericEndpointSchemeKind.webSocket => _webSocketUriBaseUrl(uri),
        _GenericEndpointSchemeKind.unsupported => null,
      },
    );
  }

  final _GenericEndpointSchemeKind kind;
  final String? baseUrl;

  bool get isSupported => kind != _GenericEndpointSchemeKind.unsupported;

  bool get isWebSocket => kind == _GenericEndpointSchemeKind.webSocket;
}
