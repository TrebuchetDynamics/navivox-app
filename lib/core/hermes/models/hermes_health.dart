import '../../protocol/navivox_json.dart';

class HermesHealthStatus {
  const HermesHealthStatus({
    required this.status,
    required this.platform,
    this.version,
    this.gatewayState,
    this.activeAgents = 0,
  });

  factory HermesHealthStatus.fromJson(Map<String, Object?> json) {
    return HermesHealthStatus(
      status: navivoxStringFromJson(json['status'], fallback: 'unknown'),
      platform: navivoxStringFromJson(
        json['platform'],
        fallback: 'hermes-agent',
      ),
      version: navivoxOptionalStringFromJson(json['version']),
      gatewayState: navivoxOptionalStringFromJson(json['gateway_state']),
      activeAgents: navivoxIntFromJson(json['active_agents']),
    );
  }

  final String status;
  final String platform;
  final String? version;
  final String? gatewayState;
  final int activeAgents;

  bool get isOk => status.toLowerCase() == 'ok';
}
