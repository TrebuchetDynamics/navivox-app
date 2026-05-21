enum NavivoxMemoryHealth { active, degraded, unavailable }

class NavivoxMemoryOverview {
  const NavivoxMemoryOverview({
    required this.profileId,
    required this.workspaceId,
    required this.databaseLabel,
    required this.health,
    required this.totalTurns,
    required this.activeMemoryItems,
    required this.observations,
    required this.conclusions,
    required this.sessionSummaries,
    required this.entities,
    required this.relationships,
    this.degradedReason = '',
    this.lastUpdatedAt,
  });

  const NavivoxMemoryOverview.degraded({
    required this.profileId,
    required String reason,
  }) : workspaceId = '',
       databaseLabel = 'redacted',
       health = NavivoxMemoryHealth.degraded,
       totalTurns = 0,
       activeMemoryItems = 0,
       observations = 0,
       conclusions = 0,
       sessionSummaries = 0,
       entities = 0,
       relationships = 0,
       degradedReason = reason,
       lastUpdatedAt = null;

  factory NavivoxMemoryOverview.fromJson(Map<String, Object?> json) {
    final counts = json['counts'];
    final countMap = counts is Map ? Map<String, Object?>.from(counts) : json;
    final healthText = json['health']?.toString().trim().toLowerCase();
    final health = switch (healthText) {
      'active' || 'ok' || 'healthy' => NavivoxMemoryHealth.active,
      'unavailable' || 'offline' => NavivoxMemoryHealth.unavailable,
      _ => NavivoxMemoryHealth.degraded,
    };

    return NavivoxMemoryOverview(
      profileId: _string(json['profile_id'], fallback: 'default'),
      workspaceId: _string(json['workspace_id'], fallback: ''),
      databaseLabel: _safeDatabaseLabel(
        json['database_label'] ?? json['database_path'],
      ),
      health: health,
      totalTurns: _int(countMap['turns'] ?? countMap['total_turns']),
      activeMemoryItems: _int(
        countMap['memory_items'] ?? countMap['active_memory_items'],
      ),
      observations: _int(countMap['observations']),
      conclusions: _int(countMap['conclusions']),
      sessionSummaries: _int(countMap['session_summaries']),
      entities: _int(countMap['entities']),
      relationships: _int(countMap['relationships']),
      degradedReason: _string(
        json['degraded_reason'] ?? json['reason'],
        fallback: '',
      ),
      lastUpdatedAt: _dateTime(json['last_updated_at']),
    );
  }

  final String profileId;
  final String workspaceId;
  final String databaseLabel;
  final NavivoxMemoryHealth health;
  final int totalTurns;
  final int activeMemoryItems;
  final int observations;
  final int conclusions;
  final int sessionSummaries;
  final int entities;
  final int relationships;
  final String degradedReason;
  final DateTime? lastUpdatedAt;

  bool get isActive => health == NavivoxMemoryHealth.active;

  String get healthLabel => switch (health) {
    NavivoxMemoryHealth.active => 'Goncho active',
    NavivoxMemoryHealth.degraded => 'Goncho degraded',
    NavivoxMemoryHealth.unavailable => 'Goncho unavailable',
  };
}

String _string(Object? value, {required String fallback}) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return fallback;
  return text;
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _dateTime(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text);
}

String _safeDatabaseLabel(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return 'redacted';

  const gormesMarker = '/.gormes/';
  final markerIndex = text.indexOf(gormesMarker);
  if (markerIndex >= 0) {
    return '~/.gormes/${text.substring(markerIndex + gormesMarker.length)}';
  }
  if (text.startsWith('/')) {
    final parts = text.split('/').where((part) => part.isNotEmpty).toList();
    final basename = parts.isEmpty ? 'memory.db' : parts.last;
    return 'redacted/$basename';
  }
  return text;
}
