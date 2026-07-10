bool hermesEndpointRequiresCleartextCredentialWarning(
  String baseUrl, {
  String? apiKey,
}) {
  if (apiKey?.trim().isEmpty ?? true) return false;
  final uri = Uri.tryParse(baseUrl.trim());
  if (uri == null || uri.scheme.toLowerCase() != 'http') return false;
  final host = uri.host.toLowerCase();
  return host != 'localhost' &&
      host != '127.0.0.1' &&
      host != '::1' &&
      host != '10.0.2.2';
}
