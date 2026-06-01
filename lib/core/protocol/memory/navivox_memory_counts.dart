import '../serialization/navivox_json.dart';

/// Count fields accepted by the memory overview wire contract.
const navivoxMemoryTotalTurnsCountFields = [
  'turns',
  'total_turns',
  'totalTurns',
];
const navivoxMemoryActiveItemsCountFields = [
  'memory_items',
  'active_memory_items',
  'activeMemoryItems',
];
const navivoxMemoryObservationsCountFields = ['observations'];
const navivoxMemoryConclusionsCountFields = ['conclusions'];
const navivoxMemorySessionSummariesCountFields = [
  'session_summaries',
  'sessionSummaries',
];
const navivoxMemoryEntitiesCountFields = ['entities'];
const navivoxMemoryRelationshipsCountFields = ['relationships'];

/// Decodes memory aggregate counters while preserving their invariant.
///
/// Memory overview counts are cardinalities from the gateway; malformed,
/// missing, or negative values cannot represent real item totals and are
/// surfaced as zero instead of leaking impossible counters into presentation.
int navivoxMemoryCountFromJson(Object? value) {
  final count = navivoxIntFromJson(value);
  return count < 0 ? 0 : count;
}

/// Replayable memory-overview count projection.
///
/// The gateway may send counters either nested under `counts` or as legacy root
/// fields. This value type makes the source-selection step explicit: a map-like
/// `counts` field is authoritative, while absent or malformed `counts` falls
/// back to the root payload.
class NavivoxMemoryOverviewCounts {
  const NavivoxMemoryOverviewCounts({
    required this.totalTurns,
    required this.activeMemoryItems,
    required this.observations,
    required this.conclusions,
    required this.sessionSummaries,
    required this.entities,
    required this.relationships,
  });

  factory NavivoxMemoryOverviewCounts.fromJson(Map<String, Object?> json) {
    return NavivoxMemoryOverviewCounts.fromCountMap(
      navivoxMemoryOverviewCountMapFromJson(json),
    );
  }

  factory NavivoxMemoryOverviewCounts.fromCountMap(
    Map<String, Object?> countMap,
  ) {
    return NavivoxMemoryOverviewCounts(
      totalTurns: navivoxMemoryCountFromJson(
        navivoxMemoryCountFieldFromJson(
          countMap,
          navivoxMemoryTotalTurnsCountFields,
        ),
      ),
      activeMemoryItems: navivoxMemoryCountFromJson(
        navivoxMemoryCountFieldFromJson(
          countMap,
          navivoxMemoryActiveItemsCountFields,
        ),
      ),
      observations: navivoxMemoryCountFromJson(
        navivoxMemoryCountFieldFromJson(
          countMap,
          navivoxMemoryObservationsCountFields,
        ),
      ),
      conclusions: navivoxMemoryCountFromJson(
        navivoxMemoryCountFieldFromJson(
          countMap,
          navivoxMemoryConclusionsCountFields,
        ),
      ),
      sessionSummaries: navivoxMemoryCountFromJson(
        navivoxMemoryCountFieldFromJson(
          countMap,
          navivoxMemorySessionSummariesCountFields,
        ),
      ),
      entities: navivoxMemoryCountFromJson(
        navivoxMemoryCountFieldFromJson(
          countMap,
          navivoxMemoryEntitiesCountFields,
        ),
      ),
      relationships: navivoxMemoryCountFromJson(
        navivoxMemoryCountFieldFromJson(
          countMap,
          navivoxMemoryRelationshipsCountFields,
        ),
      ),
    );
  }

  final int totalTurns;
  final int activeMemoryItems;
  final int observations;
  final int conclusions;
  final int sessionSummaries;
  final int entities;
  final int relationships;
}

Map<String, Object?> navivoxMemoryOverviewCountMapFromJson(
  Map<String, Object?> json,
) {
  final counts = json['counts'];
  return counts is Map ? navivoxMapFromJson(counts) : json;
}

/// Reads the first present count value for an overview field alias group.
///
/// Exact aliases are preferred in caller-supplied order, then a compatibility
/// pass accepts case/underscore drift such as `sessionSummaries` vs
/// `session_summaries`. A present malformed value remains authoritative and is
/// decoded by [navivoxMemoryCountFromJson] instead of silently falling through
/// to a later alias.
Object? navivoxMemoryCountFieldFromJson(
  Map<String, Object?> json,
  Iterable<String> names,
) {
  for (final name in names) {
    if (json.containsKey(name)) return json[name];
  }

  final canonicalNames = navivoxCanonicalWireFieldNames(names);
  for (final entry in json.entries) {
    if (canonicalNames.contains(navivoxCanonicalWireFieldName(entry.key))) {
      return entry.value;
    }
  }
  return null;
}
