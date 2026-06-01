import '../serialization/navivox_json.dart';

/// Operator-visible health state for the Gormes memory service.
enum NavivoxMemoryHealth { active, degraded, unavailable }

/// Decodes gateway memory health aliases into the UI contract.
///
/// Unknown, blank, or missing values intentionally fall back to [degraded]
/// so the app does not present ambiguous gateway state as healthy.
NavivoxMemoryHealth navivoxMemoryHealthFromJson(Object? value) {
  final healthText = navivoxOptionalStringFromJson(value)?.toLowerCase();
  return switch (healthText) {
    'active' || 'ok' || 'healthy' => NavivoxMemoryHealth.active,
    'unavailable' || 'offline' => NavivoxMemoryHealth.unavailable,
    _ => NavivoxMemoryHealth.degraded,
  };
}
