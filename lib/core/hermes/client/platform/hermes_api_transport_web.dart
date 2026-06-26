import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

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
  final request = web.XMLHttpRequest();
  final completer = Completer<String>();

  request.open(method, uri.toString(), true);
  headers.forEach(request.setRequestHeader);
  request.onLoad.listen((_) {
    final status = request.status;
    if (hermesApiIsSuccessStatus(status)) {
      completer.complete(request.responseText);
    } else {
      completer.completeError(StateError(hermesApiHttpStatusMessage(status)));
    }
  });
  request.onError.listen(
    (_) => completer.completeError(
      StateError(hermesApiHttpStatusMessage(request.status)),
    ),
  );

  final payload = body;
  if (payload == null) {
    request.send();
  } else {
    request.send(payload.toJS);
  }
  return completer.future;
}
