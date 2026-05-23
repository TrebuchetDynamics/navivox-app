class GatewayConnectionPresentation {
  const GatewayConnectionPresentation();

  String? validateBaseUrl(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Enter the Gormes gateway base URL.';
    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.host.isEmpty) {
      return 'Enter a valid Gormes gateway URL.';
    }
    if (!{'http', 'https', 'ws', 'wss'}.contains(uri.scheme)) {
      return 'Use http, https, ws, or wss.';
    }
    return null;
  }

  GatewayConnectionRequest connectRequest({
    required String baseUrl,
    required String token,
  }) {
    final trimmedToken = token.trim();
    return GatewayConnectionRequest(
      baseUrl: baseUrl.trim(),
      token: trimmedToken.isEmpty ? null : trimmedToken,
    );
  }
}

class GatewayConnectionRequest {
  const GatewayConnectionRequest({required this.baseUrl, this.token});

  final String baseUrl;
  final String? token;
}
