import '../../protocol/navivox_json.dart';

class HermesJob {
  const HermesJob({
    required this.id,
    this.name,
    this.enabled = false,
    this.state,
    this.scheduleDisplay,
    this.nextRunAt,
    this.lastRunAt,
    this.lastError,
  });

  factory HermesJob.fromJson(Map<String, Object?> json) {
    final schedule = navivoxMapFieldFromJson(json, 'schedule');
    return HermesJob(
      id: navivoxStringFromJson(json['id'], fallback: ''),
      name: navivoxOptionalStringFromJson(json['name']),
      enabled: navivoxBoolFromJson(json['enabled']),
      state: navivoxOptionalStringFromJson(json['state']),
      scheduleDisplay:
          navivoxOptionalStringFromJson(json['schedule_display']) ??
          navivoxOptionalStringFromJson(schedule['display']) ??
          navivoxOptionalStringFromJson(schedule['expr']),
      nextRunAt: navivoxOptionalStringFromJson(json['next_run_at']),
      lastRunAt: navivoxOptionalStringFromJson(json['last_run_at']),
      lastError: navivoxOptionalStringFromJson(json['last_error']),
    );
  }

  final String id;
  final String? name;
  final bool enabled;
  final String? state;
  final String? scheduleDisplay;
  final String? nextRunAt;
  final String? lastRunAt;
  final String? lastError;

  String get displayName => name == null || name!.trim().isEmpty ? id : name!;
}
