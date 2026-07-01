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

Stream<String> defaultPostStream(
  Uri uri,
  Map<String, String> headers,
  String body,
) {
  return _requestStream(uri: uri, method: 'POST', headers: headers, body: body);
}

Stream<String> defaultGetStream(Uri uri, Map<String, String> headers) {
  return _requestStream(uri: uri, method: 'GET', headers: headers);
}

Stream<String> _requestStream({
  required Uri uri,
  required String method,
  required Map<String, String> headers,
  String? body,
}) {
  final request = web.XMLHttpRequest();
  final controller = StreamController<String>();
  var delivered = 0;

  request.open(method, uri.toString(), true);
  headers.forEach((name, value) => request.setRequestHeader(name, value));
  request.onProgress.listen((_) {
    final text = request.responseText;
    if (text.length > delivered) {
      controller.add(text.substring(delivered));
      delivered = text.length;
    }
  });
  request.onLoad.listen((_) {
    if (!hermesApiIsSuccessStatus(request.status)) {
      controller.addError(
        StateError(hermesApiHttpStatusMessage(request.status)),
      );
    } else {
      final text = request.responseText;
      if (text.length > delivered) controller.add(text.substring(delivered));
    }
    controller.close();
  });
  request.onError.listen((_) {
    controller.addError(StateError(hermesApiHttpStatusMessage(request.status)));
    controller.close();
  });

  final payload = body;
  if (payload == null) {
    request.send();
  } else {
    request.send(payload.toJS);
  }
  return controller.stream;
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
  headers.forEach((name, value) => request.setRequestHeader(name, value));
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
