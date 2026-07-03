import '../hermes_api_transport.dart';

Future<String> defaultGet(Uri uri, Map<String, String> headers) {
  return unsupportedHermesApiGet(uri, headers);
}

Future<String> defaultPost(Uri uri, Map<String, String> headers, String body) {
  return unsupportedHermesApiPost(uri, headers, body);
}

Future<String> defaultPatch(Uri uri, Map<String, String> headers, String body) {
  return unsupportedHermesApiPatch(uri, headers, body);
}

Future<String> defaultDelete(Uri uri, Map<String, String> headers) {
  return unsupportedHermesApiDelete(uri, headers);
}

Stream<String> defaultPostStream(
  Uri uri,
  Map<String, String> headers,
  String body,
) {
  return unsupportedHermesApiPostStream(uri, headers, body);
}

Stream<String> defaultGetStream(Uri uri, Map<String, String> headers) {
  return unsupportedHermesApiGetStream(uri, headers);
}
