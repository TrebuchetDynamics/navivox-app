import '../serialization/navivox_json.dart';
import 'navivox_memory_degradation.dart';

enum NavivoxMemoryHealth { active, degraded, unavailable }

enum NavivoxMemoryType {
  all('all', 'All'),
  turns('turns', 'Turns'),
  memoryItems('memory_items', 'Memory items'),
  observations('observations', 'Observations'),
  conclusions('conclusions', 'Conclusions'),
  sessionSummaries('session_summaries', 'Session summaries'),
  entities('entities', 'Entities'),
  relationships('relationships', 'Relationships');

  const NavivoxMemoryType(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static NavivoxMemoryType fromWire(Object? value) {
    return navivoxValueFromWire(
      value: value,
      values: values,
      wireValue: (type) => type.wireValue,
      fallback: all,
    );
  }
}

enum NavivoxMemoryActionType {
  pin('pin', 'Pin'),
  unpin('unpin', 'Unpin'),
  archive('archive', 'Archive'),
  unarchive('unarchive', 'Unarchive'),
  markStale('mark_stale', 'Mark stale'),
  addCorrection('add_correction', 'Add correction');

  const NavivoxMemoryActionType(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static NavivoxMemoryActionType fromWire(Object? value) {
    return navivoxValueFromWire(
      value: value,
      values: values,
      wireValue: (type) => type.wireValue,
      fallback: archive,
    );
  }
}

class NavivoxMemorySearchResult {
  const NavivoxMemorySearchResult({
    required this.items,
    this.nextPageToken = '',
    this.degradedReason = '',
  });

  const NavivoxMemorySearchResult.degraded({required String reason})
    : items = const [],
      nextPageToken = '',
      degradedReason = reason;

  factory NavivoxMemorySearchResult.fromJson(Map<String, Object?> json) {
    return NavivoxMemorySearchResult(
      items: navivoxMapListFromJson(
        json['items'],
      ).map(NavivoxMemoryItem.fromJson).toList(growable: false),
      nextPageToken: navivoxStringFromJson(
        json['next_page_token'],
        fallback: '',
      ),
      degradedReason: navivoxMemoryDegradedReasonFromJson(json),
    );
  }

  final List<NavivoxMemoryItem> items;
  final String nextPageToken;
  final String degradedReason;

  bool get isDegraded => navivoxMemoryIsDegraded(degradedReason);
}

class NavivoxMemoryItem {
  const NavivoxMemoryItem({
    required this.id,
    required this.type,
    required this.snippet,
    this.timestamp = '',
    this.sessionId = '',
    this.peerId = '',
    this.status = '',
    this.tags = const [],
    this.score,
  });

  factory NavivoxMemoryItem.fromJson(Map<String, Object?> json) {
    return NavivoxMemoryItem(
      id: navivoxStringFromJson(json['id'], fallback: ''),
      type: NavivoxMemoryType.fromWire(json['type']),
      snippet: navivoxStringFromJson(
        json['snippet'] ?? json['content'],
        fallback: '',
      ),
      timestamp: navivoxStringFromJson(
        json['timestamp'] ?? json['created_at'],
        fallback: '',
      ),
      sessionId: navivoxStringFromJson(
        json['session_id'] ?? json['session_key'],
        fallback: '',
      ),
      peerId: navivoxStringFromJson(json['peer_id'], fallback: ''),
      status: navivoxStringFromJson(json['status'], fallback: ''),
      tags: navivoxStringListFromJson(json['tags']),
      score: navivoxDoubleFromJson(json['score']),
    );
  }

  final String id;
  final NavivoxMemoryType type;
  final String snippet;
  final String timestamp;
  final String sessionId;
  final String peerId;
  final String status;
  final List<String> tags;
  final double? score;
}

class NavivoxMemoryDetail {
  const NavivoxMemoryDetail({
    required this.id,
    required this.type,
    required this.content,
    this.source = '',
    this.sessionId = '',
    this.peerId = '',
    this.createdAt = '',
    this.updatedAt = '',
    this.status = '',
    this.tags = const [],
    this.provenance = '',
    this.linkedEntities = const [],
    this.linkedRelationships = const [],
    this.degradedReason = '',
  });

  const NavivoxMemoryDetail.degraded({required this.id, required String reason})
    : type = NavivoxMemoryType.all,
      content = '',
      source = '',
      sessionId = '',
      peerId = '',
      createdAt = '',
      updatedAt = '',
      status = '',
      tags = const [],
      provenance = '',
      linkedEntities = const [],
      linkedRelationships = const [],
      degradedReason = reason;

  factory NavivoxMemoryDetail.fromJson(Map<String, Object?> json) {
    return NavivoxMemoryDetail(
      id: navivoxStringFromJson(json['id'], fallback: ''),
      type: NavivoxMemoryType.fromWire(json['type']),
      content: navivoxStringFromJson(
        json['content'] ?? json['snippet'],
        fallback: '',
      ),
      source: navivoxStringFromJson(
        json['source'] ?? json['source_table'],
        fallback: '',
      ),
      sessionId: navivoxStringFromJson(
        json['session_id'] ?? json['session_key'],
        fallback: '',
      ),
      peerId: navivoxStringFromJson(json['peer_id'], fallback: ''),
      createdAt: navivoxStringFromJson(
        json['created_at'] ?? json['timestamp'],
        fallback: '',
      ),
      updatedAt: navivoxStringFromJson(json['updated_at'], fallback: ''),
      status: navivoxStringFromJson(json['status'], fallback: ''),
      tags: navivoxStringListFromJson(json['tags']),
      provenance: navivoxStringFromJson(json['provenance'], fallback: ''),
      linkedEntities: navivoxStringListFromJson(json['linked_entities']),
      linkedRelationships: navivoxStringListFromJson(
        json['linked_relationships'],
      ),
      degradedReason: navivoxMemoryDegradedReasonFromJson(json),
    );
  }

  final String id;
  final NavivoxMemoryType type;
  final String content;
  final String source;
  final String sessionId;
  final String peerId;
  final String createdAt;
  final String updatedAt;
  final String status;
  final List<String> tags;
  final String provenance;
  final List<String> linkedEntities;
  final List<String> linkedRelationships;
  final String degradedReason;

  bool get isDegraded => navivoxMemoryIsDegraded(degradedReason);
}

class NavivoxMemoryActionResult {
  const NavivoxMemoryActionResult({
    required this.accepted,
    required this.action,
    required this.message,
    this.rawSourcePreserved = true,
    this.degradedReason = '',
  });

  const NavivoxMemoryActionResult.degraded({
    required this.action,
    required String reason,
  }) : accepted = false,
       message = '',
       rawSourcePreserved = true,
       degradedReason = reason;

  factory NavivoxMemoryActionResult.fromJson(Map<String, Object?> json) {
    return NavivoxMemoryActionResult(
      accepted: navivoxBoolFromJson(json['accepted']),
      action: NavivoxMemoryActionType.fromWire(json['action']),
      message: navivoxStringFromJson(json['message'], fallback: ''),
      rawSourcePreserved: navivoxBoolFromJson(
        json['raw_source_preserved'],
        fallback: true,
      ),
      degradedReason: navivoxMemoryDegradedReasonFromJson(json),
    );
  }

  final bool accepted;
  final NavivoxMemoryActionType action;
  final String message;
  final bool rawSourcePreserved;
  final String degradedReason;

  bool get isDegraded => navivoxMemoryIsDegraded(degradedReason);
}

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
    final countMap = counts is Map ? navivoxMapFromJson(counts) : json;
    final healthText = navivoxOptionalStringFromJson(
      json['health'],
    )?.toLowerCase();
    final health = switch (healthText) {
      'active' || 'ok' || 'healthy' => NavivoxMemoryHealth.active,
      'unavailable' || 'offline' => NavivoxMemoryHealth.unavailable,
      _ => NavivoxMemoryHealth.degraded,
    };

    return NavivoxMemoryOverview(
      profileId: navivoxStringFromJson(json['profile_id'], fallback: 'default'),
      workspaceId: navivoxStringFromJson(json['workspace_id'], fallback: ''),
      databaseLabel: _safeDatabaseLabel(
        json['database_label'] ?? json['database_path'],
      ),
      health: health,
      totalTurns: navivoxIntFromJson(
        countMap['turns'] ?? countMap['total_turns'],
      ),
      activeMemoryItems: navivoxIntFromJson(
        countMap['memory_items'] ?? countMap['active_memory_items'],
      ),
      observations: navivoxIntFromJson(countMap['observations']),
      conclusions: navivoxIntFromJson(countMap['conclusions']),
      sessionSummaries: navivoxIntFromJson(countMap['session_summaries']),
      entities: navivoxIntFromJson(countMap['entities']),
      relationships: navivoxIntFromJson(countMap['relationships']),
      degradedReason: navivoxMemoryDegradedReasonFromJson(json),
      lastUpdatedAt: navivoxDateTimeFromJson(json['last_updated_at']),
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

String _safeDatabaseLabel(Object? value) {
  final text = navivoxOptionalStringFromJson(value);
  if (text == null) return 'redacted';

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
