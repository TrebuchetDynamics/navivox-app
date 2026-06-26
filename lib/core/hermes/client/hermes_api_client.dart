import 'dart:convert';

import '../../protocol/navivox_json.dart';
import '../models/hermes_capabilities.dart';
import '../models/hermes_health.dart';
import '../models/hermes_session.dart';
import '../shared/hermes_api_http.dart';
import 'hermes_api_config.dart';
import 'hermes_api_transport.dart';
import 'platform/hermes_api_transport_stub.dart'
    if (dart.library.io) 'platform/hermes_api_transport_io.dart'
    if (dart.library.html) 'platform/hermes_api_transport_web.dart'
    as transport;

class HermesApiClient {
  HermesApiClient({
    required this.config,
    HermesApiGet? get,
    HermesApiPost? post,
  }) : _get = get ?? transport.defaultGet,
       _post = post ?? transport.defaultPost;

  final HermesApiConfig config;
  final HermesApiGet _get;
  final HermesApiPost _post;

  Future<HermesHealthStatus> health() async {
    return HermesHealthStatus.fromJson(await _getJson(config.healthUri));
  }

  Future<HermesCapabilityDocument> capabilities() async {
    return HermesCapabilityDocument.fromJson(
      await _getJson(config.capabilitiesUri),
    );
  }

  Future<List<HermesSession>> listSessions() async {
    final body = await _getJson(config.sessionsUri);
    return navivoxMapListFromJson(body['data'])
        .map(HermesSession.fromJson)
        .where((session) => session.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<HermesSession> createSession({
    required String id,
    String? title,
    String? model,
    String? systemPrompt,
  }) async {
    final body = <String, Object?>{
      'id': id.trim(),
      ...navivoxTrimmedStringFields({
        'title': title,
        'model': model,
        'system_prompt': systemPrompt,
      }),
    };
    final response = await _postJson(config.sessionsUri, body);
    return HermesSession.fromJson(navivoxMapFieldFromJson(response, 'session'));
  }

  Future<List<HermesMessage>> sessionMessages(String sessionId) async {
    final body = await _getJson(config.sessionMessagesUri(sessionId));
    return navivoxMapListFromJson(
      body['data'],
    ).map(HermesMessage.fromJson).toList(growable: false);
  }

  Future<Map<String, Object?>> _getJson(Uri uri) async {
    return _decodeObject(await _get(uri, config.headers));
  }

  Future<Map<String, Object?>> _postJson(
    Uri uri,
    Map<String, Object?> body,
  ) async {
    final headers = <String, String>{
      ...config.headers,
      hermesApiContentTypeHeader: hermesApiJsonContentType,
    };
    return _decodeObject(await _post(uri, headers, jsonEncode(body)));
  }

  Map<String, Object?> _decodeObject(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      throw const FormatException('Hermes API response must be a JSON object');
    }
    return navivoxMapFromJson(decoded);
  }
}
