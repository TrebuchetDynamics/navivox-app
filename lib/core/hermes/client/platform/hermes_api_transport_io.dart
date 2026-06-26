import 'dart:convert';
import 'dart:io';

import '../../shared/hermes_api_http.dart';

Future<String> defaultGet(Uri uri, Map<String, String> headers) {
  return _request(uri: uri, method: 'GET', headers: headers);
}

Future<String> defaultPost(Uri uri, Map<String, String> headers, String body) {
  return _request(uri: uri, method: 'POST', headers: headers, body: body);
}

Future<String> _request({
  required Uri uri,
  required String method,
  required Map<String, String> headers,
  String? body,
}) async {
  final client = HttpClient();
  try {
    final request = await client.openUrl(method, uri);
    request.followRedirects = false;
    headers.forEach(request.headers.set);
    final payload = body;
    if (payload != null) request.write(payload);
    final response = await request.close();
    final responseBody = await utf8.decoder.bind(response).join();
    if (!hermesApiIsSuccessStatus(response.statusCode)) {
      throw HttpException(
        hermesApiHttpStatusMessage(response.statusCode),
        uri: uri,
      );
    }
    return responseBody;
  } finally {
    client.close(force: true);
  }
}
