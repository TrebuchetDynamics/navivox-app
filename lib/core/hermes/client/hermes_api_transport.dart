typedef HermesApiGet =
    Future<String> Function(Uri uri, Map<String, String> headers);

typedef HermesApiPost =
    Future<String> Function(Uri uri, Map<String, String> headers, String body);

typedef HermesApiPatch =
    Future<String> Function(Uri uri, Map<String, String> headers, String body);

typedef HermesApiPut =
    Future<String> Function(Uri uri, Map<String, String> headers, String body);

typedef HermesApiDelete =
    Future<String> Function(Uri uri, Map<String, String> headers);

typedef HermesApiPostStream =
    Stream<String> Function(Uri uri, Map<String, String> headers, String body);

typedef HermesApiGetStream =
    Stream<String> Function(Uri uri, Map<String, String> headers);

Future<String> unsupportedHermesApiGet(Uri uri, Map<String, String> headers) {
  throw UnsupportedError('Hermes API HTTP GET transport is not configured.');
}

Stream<String> unsupportedHermesApiGetStream(
  Uri uri,
  Map<String, String> headers,
) {
  throw UnsupportedError(
    'Hermes API HTTP streaming GET transport is not configured.',
  );
}

Future<String> unsupportedHermesApiPost(
  Uri uri,
  Map<String, String> headers,
  String body,
) {
  throw UnsupportedError('Hermes API HTTP POST transport is not configured.');
}

Future<String> unsupportedHermesApiPatch(
  Uri uri,
  Map<String, String> headers,
  String body,
) {
  throw UnsupportedError('Hermes API HTTP PATCH transport is not configured.');
}

Future<String> unsupportedHermesApiPut(
  Uri uri,
  Map<String, String> headers,
  String body,
) {
  throw UnsupportedError('Hermes API HTTP PUT transport is not configured.');
}

Future<String> unsupportedHermesApiDelete(
  Uri uri,
  Map<String, String> headers,
) {
  throw UnsupportedError('Hermes API HTTP DELETE transport is not configured.');
}

Stream<String> unsupportedHermesApiPostStream(
  Uri uri,
  Map<String, String> headers,
  String body,
) {
  throw UnsupportedError(
    'Hermes API HTTP streaming POST transport is not configured.',
  );
}
