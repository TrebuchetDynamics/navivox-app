class HermesDetachedRunLease {
  const HermesDetachedRunLease({
    required this.runId,
    required this.sessionId,
    required this.baseUrl,
    required this.createdAt,
    this.profileId,
  });

  factory HermesDetachedRunLease.fromJson(Map<String, Object?> json) {
    String requiredString(String name, {int maximumLength = 512}) {
      final value = json[name];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('Detached run $name is missing.');
      }
      final trimmed = value.trim();
      if (trimmed.length > maximumLength) {
        throw FormatException('Detached run $name is too long.');
      }
      return trimmed;
    }

    final createdAt = DateTime.tryParse(requiredString('created_at'))?.toUtc();
    if (createdAt == null) {
      throw const FormatException('Detached run created_at is invalid.');
    }
    final profileValue = json['profile_id'];
    final profileId = profileValue is String && profileValue.trim().isNotEmpty
        ? profileValue.trim()
        : null;
    if (profileId != null && profileId.length > 256) {
      throw const FormatException('Detached run profile_id is too long.');
    }
    return HermesDetachedRunLease(
      runId: requiredString('run_id', maximumLength: 256),
      sessionId: requiredString('session_id', maximumLength: 256),
      baseUrl: requiredString('base_url', maximumLength: 2048),
      profileId: profileId,
      createdAt: createdAt,
    );
  }

  final String runId;
  final String sessionId;
  final String baseUrl;
  final String? profileId;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'run_id': runId,
    'session_id': sessionId,
    'base_url': baseUrl,
    if (profileId != null) 'profile_id': profileId,
    'created_at': createdAt.toUtc().toIso8601String(),
  };
}

abstract interface class HermesDetachedRunStore {
  Future<List<HermesDetachedRunLease>> load();

  Future<void> save(List<HermesDetachedRunLease> leases);
}
