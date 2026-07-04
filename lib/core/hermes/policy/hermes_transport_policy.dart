import '../models/hermes_capabilities.dart';

class HermesTransportPolicy {
  const HermesTransportPolicy(this.capabilities);

  final HermesCapabilityDocument capabilities;

  bool get supportsSessionChatStream {
    return capabilities.supportsFeature('session_chat_streaming') &&
        capabilities.advertisesEndpoint(
          'session_chat_stream',
          'POST',
          '/api/sessions/{session_id}/chat/stream',
        );
  }

  bool get supportsAnyChatTransport =>
      supportsSessionChatStream || supportsRunsTransport;

  bool get supportsRunsTransport {
    return capabilities.supportsFeature('run_submission') &&
        capabilities.supportsFeature('run_events_sse') &&
        capabilities.advertisesEndpoint('runs', 'POST', '/v1/runs') &&
        capabilities.advertisesEndpoint(
          'run_events',
          'GET',
          '/v1/runs/{run_id}/events',
        );
  }

  bool get supportsRunStatus =>
      capabilities.supportsFeature('run_status') &&
      capabilities.advertisesEndpoint('run_status', 'GET', '/v1/runs/{run_id}');

  bool get supportsRunStop =>
      capabilities.supportsFeature('run_stop') &&
      capabilities.advertisesEndpoint(
        'run_stop',
        'POST',
        '/v1/runs/{run_id}/stop',
      );

  bool get supportsRunApprovalResponse =>
      capabilities.supportsFeature('run_approval_response') &&
      capabilities.advertisesEndpoint(
        'run_approval',
        'POST',
        '/v1/runs/{run_id}/approval',
      );

  bool get supportsToolProgressEvents =>
      capabilities.supportsFeature('tool_progress_events');

  bool get supportsConfigWrite =>
      capabilities.supportsFeature('admin_config_rw');
  bool get supportsMemoryWrite =>
      capabilities.supportsFeature('memory_write_api');
  bool get supportsAudioApi => capabilities.supportsFeature('audio_api');
  bool get supportsRealtimeVoice =>
      capabilities.supportsFeature('realtime_voice');
}
