import '../../../core/hermes/channel/hermes_channel_state.dart';
import '../../../core/hermes/policy/hermes_surface_readiness.dart';
import '../../../core/hermes/policy/hermes_transport_policy.dart';

/// Builds a bounded, copyable Hermes operator diagnostic snapshot.
///
/// This intentionally exports only state already visible in the Hermes UI or
/// safe capability metadata. It does not include API keys, request headers, raw
/// logs, tool payloads, transcripts, or platform error dumps.
String hermesDiagnosticsExport(HermesChannelState state) {
  final buffer = StringBuffer()
    ..writeln('Navivox Hermes diagnostics')
    ..writeln('Connection: ${state.status.name}')
    ..writeln('Sessions: ${state.sessions.length}')
    ..writeln(
      'Active session: ${state.activeSession?.title ?? state.activeSessionId ?? 'none'}',
    )
    ..writeln('Active messages: ${state.activeMessages.length}');

  final health = state.detailedHealth;
  if (health != null) {
    buffer
      ..writeln('Health status: ${health.status}')
      ..writeln('Platform: ${health.platform}')
      ..writeln('Version: ${health.version ?? 'unknown'}')
      ..writeln('Gateway state: ${health.gatewayState ?? 'unknown'}')
      ..writeln('Active agents: ${health.activeAgents}');
  }

  final capabilities = state.capabilities;
  if (capabilities != null) {
    final policy = HermesTransportPolicy(capabilities);
    final featureNames = capabilities.features.keys.toList()..sort();
    final endpointNames = capabilities.endpoints.keys.toList()..sort();
    buffer
      ..writeln('Capability model: ${capabilities.model}')
      ..writeln('Auth required: ${capabilities.auth.required}')
      ..writeln(
        'Run transport: ${policy.supportsRunsTransport ? 'available' : 'unavailable'}',
      )
      ..writeln(
        'Run stop: ${policy.supportsRunStop ? 'available' : 'not advertised'}',
      )
      ..writeln(
        'Run approval response: ${policy.supportsRunApprovalResponse ? 'available' : 'not advertised'}',
      )
      ..writeln(
        'Tool progress events: ${policy.supportsToolProgressEvents ? 'advertised' : 'not advertised'}',
      )
      ..writeln(
        'Session stream: ${policy.supportsSessionChatStream ? 'available' : 'unavailable'}',
      )
      ..writeln(
        'Realtime voice: ${policy.supportsRealtimeVoice ? 'advertised' : 'not advertised'}',
      )
      ..writeln(
        'Config write: ${policy.supportsConfigWrite ? 'advertised' : 'not advertised'}',
      )
      ..writeln(
        'Memory write: ${policy.supportsMemoryWrite ? 'advertised' : 'not advertised'}',
      )
      ..writeln(
        'Features: ${featureNames.isEmpty ? 'none' : featureNames.join(', ')}',
      )
      ..writeln(
        'Endpoints: ${endpointNames.isEmpty ? 'none' : endpointNames.join(', ')}',
      )
      ..writeln('Surface readiness:');
    for (final item in hermesSurfaceReadiness(capabilities)) {
      buffer.writeln('- ${item.title}: ${item.status.label} — ${item.detail}');
    }
  }

  buffer
    ..writeln(
      'Models: ${state.models.isEmpty ? 'none' : state.models.join(', ')}',
    )
    ..writeln('Skills: ${state.skills.length}')
    ..writeln('Enabled toolsets: ${state.enabledToolsets.length}')
    ..writeln('Jobs: ${state.jobs.length}')
    ..writeln('Secrets: excluded');

  return buffer.toString().trimRight();
}
