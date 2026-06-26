import '../shared/hermes_api_http.dart';
import '../shared/hermes_api_uri.dart';

class HermesApiConfig {
  const HermesApiConfig({required this.baseUri, this.apiKey});

  factory HermesApiConfig.fromBaseUrl(String baseUrl, {String? apiKey}) {
    return HermesApiConfig(baseUri: Uri.parse(baseUrl), apiKey: apiKey);
  }

  final Uri baseUri;
  final String? apiKey;

  Uri get healthUri => _withPath('/health');
  Uri get healthDetailedUri => _withPath('/health/detailed');
  Uri get capabilitiesUri => _withPath('/v1/capabilities');
  Uri get modelsUri => _withPath('/v1/models');
  Uri get skillsUri => _withPath('/v1/skills');
  Uri get toolsetsUri => _withPath('/v1/toolsets');
  Uri get sessionsUri => _withPath('/api/sessions');
  Uri get runsUri => _withPath('/v1/runs');

  Uri sessionUri(String sessionId) => _withPath(
    '/api/sessions/${hermesApiTrimmedPathSegment(sessionId, name: 'sessionId')}',
  );

  Uri sessionMessagesUri(String sessionId) => _withPath(
    '/api/sessions/${hermesApiTrimmedPathSegment(sessionId, name: 'sessionId')}/messages',
  );

  Uri sessionChatUri(String sessionId) => _withPath(
    '/api/sessions/${hermesApiTrimmedPathSegment(sessionId, name: 'sessionId')}/chat',
  );

  Uri sessionChatStreamUri(String sessionId) => _withPath(
    '/api/sessions/${hermesApiTrimmedPathSegment(sessionId, name: 'sessionId')}/chat/stream',
  );

  Uri runUri(String runId) => _withPath(
    '/v1/runs/${hermesApiTrimmedPathSegment(runId, name: 'runId')}',
  );

  Uri runEventsUri(String runId) => _withPath(
    '/v1/runs/${hermesApiTrimmedPathSegment(runId, name: 'runId')}/events',
  );

  Uri runApprovalUri(String runId) => _withPath(
    '/v1/runs/${hermesApiTrimmedPathSegment(runId, name: 'runId')}/approval',
  );

  Uri runStopUri(String runId) => _withPath(
    '/v1/runs/${hermesApiTrimmedPathSegment(runId, name: 'runId')}/stop',
  );

  Map<String, String> get headers {
    final value = apiKey?.trim();
    if (value == null || value.isEmpty) return const {};
    return {hermesApiAuthorizationHeader: hermesApiBearerAuthorization(value)};
  }

  Uri _withPath(String path) => hermesApiEndpointUri(baseUri, path);
}
