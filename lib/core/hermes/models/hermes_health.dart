import '../../protocol/wing_json.dart';

const _maxHealthCount = 1000000;
const _maxHealthPlatforms = 32;
const _knownReadinessChecks = <String>[
  'state_db',
  'config',
  'model',
  'disk',
  'gateway',
  'background_queues',
];

class HermesHealthStatus {
  const HermesHealthStatus({
    required this.status,
    required this.platform,
    this.version,
    this.gatewayState,
    this.activeAgents = 0,
    this.gatewayBusy,
    this.gatewayDrainable,
    this.exitReason,
    this.updatedAt,
    this.pid,
    this.platforms = const [],
    this.readiness,
  });

  factory HermesHealthStatus.fromJson(Map<String, Object?> json) {
    return HermesHealthStatus(
      status: wingStringFromJson(json['status'], fallback: 'unknown'),
      platform: wingStringFromJson(json['platform'], fallback: 'hermes-agent'),
      version: wingOptionalStringFromJson(json['version']),
      gatewayState: wingOptionalStringFromJson(json['gateway_state']),
      activeAgents: _boundedInt(json['active_agents']) ?? 0,
      gatewayBusy: _optionalBool(json['gateway_busy']),
      gatewayDrainable: _optionalBool(json['gateway_drainable']),
      exitReason: _boundedLiteralText(json['exit_reason'], 160),
      updatedAt: _timestamp(json['updated_at']),
      pid: _boundedInt(json['pid'], min: 1, max: 2147483647),
      platforms: _parsePlatforms(json['platforms']),
      readiness: HermesGatewayReadiness.fromJson(json['readiness']),
    );
  }

  final String status;
  final String platform;
  final String? version;
  final String? gatewayState;
  final int activeAgents;
  final bool? gatewayBusy;
  final bool? gatewayDrainable;
  final String? exitReason;
  final String? updatedAt;
  final int? pid;
  final List<HermesGatewayPlatformStatus> platforms;
  final HermesGatewayReadiness? readiness;

  bool get isOk => status.toLowerCase() == 'ok';
}

class HermesGatewayPlatformStatus {
  const HermesGatewayPlatformStatus({required this.name, required this.status});

  final String name;
  final String status;
}

class HermesGatewayReadiness {
  const HermesGatewayReadiness({required this.status, required this.checks});

  factory HermesGatewayReadiness.fromJson(Object? value) {
    final json = wingMapFromJson(value);
    if (json.isEmpty) return const HermesGatewayReadiness._absent();
    final checksJson = wingMapFromJson(json['checks']);
    return HermesGatewayReadiness(
      status: _boundedLiteralText(json['status'], 32) ?? 'unknown',
      checks: [
        for (final id in _knownReadinessChecks)
          if (wingMapFromJson(checksJson[id]).isNotEmpty)
            HermesGatewayReadinessCheck.fromJson(
              id,
              wingMapFromJson(checksJson[id]),
            ),
      ],
    );
  }

  const HermesGatewayReadiness._absent() : status = '', checks = const [];

  final String status;
  final List<HermesGatewayReadinessCheck> checks;

  bool get isAbsent => status.isEmpty && checks.isEmpty;
}

class HermesGatewayReadinessCheck {
  const HermesGatewayReadinessCheck({
    required this.id,
    required this.status,
    this.detail,
    this.usedPercent,
    this.freeBytes,
    this.runtimeState,
    this.connectedPlatforms,
    this.configuredPlatforms,
    this.activeApiRuns,
    this.processCompletions,
    this.activeDelegations,
  });

  factory HermesGatewayReadinessCheck.fromJson(
    String id,
    Map<String, Object?> json,
  ) => HermesGatewayReadinessCheck(
    id: id,
    status: _boundedLiteralText(json['status'], 32) ?? 'unknown',
    detail: _boundedLiteralText(json['detail'], 160),
    usedPercent: _boundedDouble(json['used_percent'], min: 0, max: 100),
    freeBytes: _boundedInt(json['free_bytes'], max: 9000000000000000),
    runtimeState: _boundedLiteralText(json['state'], 80),
    connectedPlatforms: _boundedInt(json['connected_platforms']),
    configuredPlatforms: _boundedInt(json['platforms']),
    activeApiRuns: _boundedInt(json['active_api_runs']),
    processCompletions: _boundedInt(json['process_completions']),
    activeDelegations: _boundedInt(json['active_delegations']),
  );

  final String id;
  final String status;
  final String? detail;
  final double? usedPercent;
  final int? freeBytes;
  final String? runtimeState;
  final int? connectedPlatforms;
  final int? configuredPlatforms;
  final int? activeApiRuns;
  final int? processCompletions;
  final int? activeDelegations;
}

List<HermesGatewayPlatformStatus> _parsePlatforms(Object? value) {
  final entries = wingMapFromJson(value).entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));
  return [
    for (final entry in entries.take(_maxHealthPlatforms))
      if (_boundedLiteralText(entry.key, 80) case final name?)
        HermesGatewayPlatformStatus(
          name: name,
          status:
              _boundedLiteralText(wingMapFromJson(entry.value)['state'], 80) ??
              _boundedLiteralText(wingMapFromJson(entry.value)['status'], 80) ??
              'unknown',
        ),
  ];
}

bool? _optionalBool(Object? value) => value is bool ? value : null;

String? _boundedLiteralText(Object? value, int maxLength) {
  if (value is! String) return null;
  final normalized = value
      .replaceAll(RegExp(r'[\u0000-\u001f\u007f]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (normalized.isEmpty) return null;
  if (normalized.length <= maxLength) return normalized;
  return '${normalized.substring(0, maxLength - 1)}…';
}

int? _boundedInt(Object? value, {int min = 0, int max = _maxHealthCount}) {
  final number = value is num
      ? value
      : value is String
      ? num.tryParse(value.trim())
      : null;
  if (number == null || !number.isFinite) return null;
  final integer = number.toInt();
  if (integer != number || integer < min || integer > max) return null;
  return integer;
}

double? _boundedDouble(Object? value, {double min = 0, double max = 100}) {
  final parsed = value is num
      ? value.toDouble()
      : value is String
      ? double.tryParse(value.trim())
      : null;
  if (parsed == null || !parsed.isFinite || parsed < min || parsed > max) {
    return null;
  }
  return parsed;
}

String? _timestamp(Object? value) {
  if (value is num && value.isFinite && value >= 0) {
    final milliseconds = value >= 100000000000
        ? value.round()
        : (value * 1000).round();
    try {
      return DateTime.fromMillisecondsSinceEpoch(
        milliseconds,
        isUtc: true,
      ).toIso8601String();
    } on RangeError {
      return null;
    }
  }
  return _boundedLiteralText(value, 80);
}
