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
      'Active session: ${_safeDiagnosticsText(state.activeSession?.title ?? state.activeSessionId ?? 'none')}',
    )
    ..writeln('Active messages: ${state.activeMessages.length}');

  final health = state.detailedHealth;
  if (health != null) {
    buffer
      ..writeln('Health status: ${_safeDiagnosticsText(health.status)}')
      ..writeln('Platform: ${_safeDiagnosticsText(health.platform)}')
      ..writeln('Version: ${_safeDiagnosticsText(health.version ?? 'unknown')}')
      ..writeln(
        'Gateway state: ${_safeDiagnosticsText(health.gatewayState ?? 'unknown')}',
      )
      ..writeln('Active agents: ${health.activeAgents}');
  }

  final capabilities = state.capabilities;
  if (capabilities != null) {
    final policy = HermesTransportPolicy(capabilities);
    final featureNames = capabilities.features.keys.toList()..sort();
    final endpointNames = capabilities.endpoints.keys.toList()..sort();
    buffer
      ..writeln('Capability model: ${_safeDiagnosticsText(capabilities.model)}')
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
        'Audio API: ${policy.supportsAudioApi ? 'advertised' : 'not advertised'}',
      )
      ..writeln('Voice path: device STT -> Hermes text; server audio not wired')
      ..writeln(
        'Config write: ${policy.supportsConfigWrite ? 'advertised' : 'not advertised'}',
      )
      ..writeln(
        'Memory write: ${policy.supportsMemoryWrite ? 'advertised' : 'not advertised'}',
      )
      ..writeln('Features: ${_safeDiagnosticsList(featureNames)}')
      ..writeln('Endpoints: ${_safeDiagnosticsList(endpointNames)}')
      ..writeln('Surface readiness:');
    for (final item in hermesSurfaceReadiness(capabilities)) {
      buffer.writeln(
        '- ${_safeDiagnosticsText(item.title)}: ${item.status.label} — ${_safeDiagnosticsText(item.detail, maxLength: 240)}',
      );
    }
  }

  buffer
    ..writeln('Models: ${_safeDiagnosticsList(state.models)}')
    ..writeln('Skills: ${state.skills.length}')
    ..writeln('Enabled toolsets: ${state.enabledToolsets.length}')
    ..writeln('Jobs: ${state.jobs.length}')
    ..writeln('Secrets: excluded');

  return buffer.toString().trimRight();
}

String _safeDiagnosticsList(List<String> values) {
  if (values.isEmpty) return 'none';
  final safe = values
      .take(12)
      .map((value) => _safeDiagnosticsText(value, maxLength: 80))
      .join(', ');
  final remaining = values.length - 12;
  return remaining > 0 ? '$safe, +$remaining more' : safe;
}

String _safeDiagnosticsText(String text, {int maxLength = 120}) {
  var safe = text.replaceAll(
    RegExp(r'bearer\s+\S+', caseSensitive: false),
    'Bearer [redacted]',
  );
  safe = safe.replaceAllMapped(
    RegExp(r'(authorization\s*[:=]\s*basic\s+)\S+', caseSensitive: false),
    (match) => '${match[1]}[redacted]',
  );
  safe = safe.replaceAllMapped(
    RegExp(r'(authorization\s*[:=]\s*)\S+', caseSensitive: false),
    (match) => '${match[1]}[redacted]',
  );
  safe = safe.replaceAllMapped(
    RegExp(r'Basic\s+[^\s,;]+', caseSensitive: false),
    (_) => 'Basic [redacted]',
  );
  safe = safe.replaceAllMapped(
    RegExp(
      r'((?:Cookie|Set-Cookie|X-API-Key|X-Auth-Token)\s*[:=]\s*)[^\n\r,;]+',
      caseSensitive: false,
    ),
    (match) => '${match[1]}[redacted]',
  );
  safe = safe.replaceAllMapped(
    RegExp(r'([a-z][a-z0-9+.-]*://)([^/\s@]+@)', caseSensitive: false),
    (match) => '${match[1]}[redacted]@',
  );
  safe = safe.replaceAllMapped(
    RegExp(
      r'((?:api[-_ ]?key|auth[-_ ]?token|token|secret|password|passwd|pwd|credential)\s*[:=]\s*)\S+',
      caseSensitive: false,
    ),
    (match) => '${match[1]}[redacted]',
  );
  safe = safe
      .replaceAll(
        RegExp(r'sk-[a-z0-9_-]{12,}', caseSensitive: false),
        'sk-[redacted]',
      )
      .replaceAll(
        RegExp(r'gh[pousr]_[a-z0-9_]{20,}', caseSensitive: false),
        'ghp_[redacted]',
      )
      .replaceAll(
        RegExp(r'xox[abprs]-[a-z0-9-]{20,}', caseSensitive: false),
        'xox-[redacted]',
      )
      .replaceAll(
        RegExp(
          r'eyJ[a-z0-9_-]{8,}\.[a-z0-9_-]{8,}\.[a-z0-9_-]{8,}',
          caseSensitive: false,
        ),
        '[redacted-jwt]',
      )
      .replaceAll(
        RegExp(r'secret[-_a-z0-9.]*', caseSensitive: false),
        '[redacted]',
      );
  if (safe.length <= maxLength) return safe;
  return '${safe.substring(0, maxLength).trimRight()}…';
}
