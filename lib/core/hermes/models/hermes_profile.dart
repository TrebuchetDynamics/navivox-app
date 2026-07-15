import '../../protocol/navivox_json.dart';

/// A Hermes Agent profile ("agent") as advertised by `GET /api/profiles`.
///
/// Profiles are administrative, revisioned resources owned by the Hermes
/// Agent. Navivox never infers profile identity: [id] is the stable wire key
/// used for path segments and the mandatory `profile` query on profile-owned
/// operations, while [revision] is the optimistic-concurrency token echoed
/// back as `If-Match` on edits.
class HermesProfile {
  const HermesProfile({
    required this.id,
    required this.displayName,
    required this.revision,
    this.description = '',
    this.model = '',
    this.skillsCount = 0,
    this.gatewayRunning = false,
    this.avatar,
    this.color,
  });

  /// Parses one profile row defensively. Rows whose [id] is blank must be
  /// discarded by callers (see `HermesApiClient.listProfiles`) because a
  /// profile without a stable key cannot be selected or scoped safely.
  factory HermesProfile.fromJson(Map<String, Object?> json) {
    return HermesProfile(
      id: navivoxStringFromJson(json['id'], fallback: ''),
      displayName: navivoxStringFromJson(json['name'], fallback: ''),
      revision: navivoxStringFromJson(json['revision'], fallback: ''),
      description: navivoxStringFromJson(json['description'], fallback: ''),
      model: navivoxStringFromJson(json['model'], fallback: ''),
      skillsCount: navivoxIntFromJson(json['skills_count']),
      gatewayRunning: navivoxBoolFromJson(json['gateway_running']),
      avatar: navivoxOptionalStringFromJson(json['avatar']),
      color: navivoxOptionalStringFromJson(json['color']),
    );
  }

  final String id;
  final String displayName;
  final String revision;
  final String description;
  final String model;
  final int skillsCount;
  final bool gatewayRunning;
  final String? avatar;
  final String? color;
}

/// The persona ("SOUL") document for a single profile, returned by
/// `GET /api/profiles/{name}/soul` and written back with `PUT`. [revision] is
/// the persona-domain concurrency token, distinct from the profile row's own
/// revision, and must be echoed as `If-Match` on writes.
class HermesProfileSoul {
  const HermesProfileSoul({required this.soul, required this.revision});

  factory HermesProfileSoul.fromJson(Map<String, Object?> json) {
    return HermesProfileSoul(
      soul: navivoxStringFromJson(json['soul'], fallback: ''),
      revision: navivoxStringFromJson(json['revision'], fallback: ''),
    );
  }

  final String soul;
  final String revision;
}
