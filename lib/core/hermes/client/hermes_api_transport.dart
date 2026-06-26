typedef HermesApiGet =
    Future<String> Function(Uri uri, Map<String, String> headers);

typedef HermesApiPost =
    Future<String> Function(Uri uri, Map<String, String> headers, String body);

Future<String> unsupportedHermesApiGet(Uri uri, Map<String, String> headers) {
  throw UnsupportedError('Hermes API HTTP GET transport is not configured.');
}

Future<String> unsupportedHermesApiPost(
  Uri uri,
  Map<String, String> headers,
  String body,
) {
  throw UnsupportedError('Hermes API HTTP POST transport is not configured.');
}
