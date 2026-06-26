import 'dart:convert';

import '../../protocol/navivox_json.dart';

class HermesSseEvent {
  const HermesSseEvent({this.id, required this.event, required this.data});

  final String? id;
  final String event;
  final String data;

  bool get isDone => event == 'done' || data.trim() == '[DONE]';
}

class HermesStreamEvent {
  const HermesStreamEvent({required this.name, required this.payload});

  factory HermesStreamEvent.done() {
    return const HermesStreamEvent(name: 'done', payload: {});
  }

  factory HermesStreamEvent.fromSse(HermesSseEvent event) {
    if (event.isDone) return HermesStreamEvent.done();
    final decoded = jsonDecode(event.data);
    if (decoded is! Map) {
      throw const FormatException('Hermes SSE data must be a JSON object');
    }
    return HermesStreamEvent(
      name: event.event,
      payload: navivoxMapFromJson(decoded),
    );
  }

  final String name;
  final Map<String, Object?> payload;

  bool get isDone => name == 'done';
  String? get runId => navivoxOptionalStringFromJson(payload['run_id']);
  String? get sessionId => navivoxOptionalStringFromJson(payload['session_id']);
  String? get messageId => navivoxOptionalStringFromJson(payload['message_id']);
  String? get delta => navivoxOptionalStringFromJson(payload['delta']);
}

/// Pure Dart server-sent event decoder for Hermes HTTP streams.
class HermesSseEventDecoder {
  const HermesSseEventDecoder();

  List<HermesSseEvent> decode(Iterable<String> chunks) {
    final events = <HermesSseEvent>[];
    final buffer = StringBuffer();
    for (final chunk in chunks) {
      buffer.write(chunk);
      _drainEvents(buffer, events);
    }
    return events;
  }

  List<HermesStreamEvent> decodeJsonEvents(Iterable<String> chunks) {
    final events = <HermesStreamEvent>[];
    for (final event in decode(chunks)) {
      try {
        events.add(HermesStreamEvent.fromSse(event));
      } on FormatException {
        continue;
      }
    }
    return events;
  }

  void _drainEvents(StringBuffer buffer, List<HermesSseEvent> events) {
    var text = buffer.toString();
    var separator = _eventSeparatorIndex(text);
    if (separator.index == -1) return;

    buffer.clear();
    while (separator.index != -1) {
      final frame = text.substring(0, separator.index);
      final event = _parseFrame(frame);
      if (event != null) events.add(event);
      text = text.substring(separator.index + separator.length);
      separator = _eventSeparatorIndex(text);
    }
    buffer.write(text);
  }

  _SseSeparator _eventSeparatorIndex(String text) {
    final crlf = text.indexOf('\r\n\r\n');
    final lf = text.indexOf('\n\n');
    if (crlf == -1 && lf == -1) return const _SseSeparator(-1, 0);
    if (crlf != -1 && (lf == -1 || crlf < lf)) {
      return _SseSeparator(crlf, 4);
    }
    return _SseSeparator(lf, 2);
  }

  HermesSseEvent? _parseFrame(String frame) {
    String? id;
    var event = 'message';
    final dataLines = <String>[];

    for (final line in frame.replaceAll('\r\n', '\n').split('\n')) {
      if (line.isEmpty || line.startsWith(':')) continue;
      final colon = line.indexOf(':');
      final field = colon == -1 ? line : line.substring(0, colon);
      var value = colon == -1 ? '' : line.substring(colon + 1);
      if (value.startsWith(' ')) value = value.substring(1);
      if (field == 'id') {
        id = value;
      } else if (field == 'event') {
        event = value.isEmpty ? 'message' : value;
      } else if (field == 'data') {
        dataLines.add(value);
      }
    }

    if (dataLines.isEmpty) return null;
    final data = dataLines.join('\n');
    return HermesSseEvent(
      id: id,
      event: data.trim() == '[DONE]' ? 'done' : event,
      data: data,
    );
  }
}

class _SseSeparator {
  const _SseSeparator(this.index, this.length);

  final int index;
  final int length;
}
