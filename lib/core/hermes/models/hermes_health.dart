import '../../protocol/navivox_json.dart';

class HermesHealthStatus {
  const HermesHealthStatus({
    required this.status,
    required this.platform,
    this.version,
  });

  factory HermesHealthStatus.fromJson(Map<String, Object?> json) {
    return HermesHealthStatus(
      status: navivoxStringFromJson(json['status'], fallback: 'unknown'),
      platform: navivoxStringFromJson(
        json['platform'],
        fallback: 'hermes-agent',
      ),
      version: navivoxOptionalStringFromJson(json['version']),
    );
  }

  final String status;
  final String platform;
  final String? version;

  bool get isOk => status.toLowerCase() == 'ok';
}
