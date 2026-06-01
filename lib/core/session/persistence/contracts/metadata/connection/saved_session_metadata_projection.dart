/// Replayable projection of one saved-session metadata value.
///
/// This keeps the decision shape shared across base URL and websocket metadata:
/// a raw value is either absent, transformed to durable reconnect metadata,
/// preserved as legacy text, or rejected because it is URL-shaped but unsafe.
enum SavedSessionMetadataProjectionKind { absent, durable, legacy, rejectedUrl }

class SavedSessionMetadataProjection {
  const SavedSessionMetadataProjection.absent()
    : projectedValue = null,
      kind = SavedSessionMetadataProjectionKind.absent;

  const SavedSessionMetadataProjection.durable(String value)
    : assert(value.length > 0, 'durable projection values must not be blank'),
      projectedValue = value,
      kind = SavedSessionMetadataProjectionKind.durable;

  const SavedSessionMetadataProjection.legacy(String value)
    : assert(value.length > 0, 'legacy projection values must not be blank'),
      projectedValue = value,
      kind = SavedSessionMetadataProjectionKind.legacy;

  const SavedSessionMetadataProjection.rejectedUrl()
    : projectedValue = null,
      kind = SavedSessionMetadataProjectionKind.rejectedUrl;

  /// The non-secret value to persist or replay.
  ///
  /// Legacy compatibility text deliberately appears here too; callers that need
  /// to distinguish sanitized endpoint metadata from legacy text must inspect
  /// [kind] or [isLegacyText] instead of inferring from value presence.
  final String? projectedValue;
  final SavedSessionMetadataProjectionKind kind;

  /// Value that may be safely written back to saved-session metadata.
  ///
  /// This includes both sanitized durable endpoint values and legacy
  /// compatibility text. Reconnect capability decisions must still inspect
  /// [kind] before treating the value as a parsed endpoint.
  String? get persistableValue => projectedValue;

  /// Backwards-compatible alias for [persistableValue].
  ///
  /// Some callers historically used this for all persisted metadata, including
  /// legacy text; keep that behavior explicit rather than changing public shape.
  String? get durableValue => persistableValue;

  bool get isDurableEndpoint =>
      kind == SavedSessionMetadataProjectionKind.durable;
  bool get isLegacyText => kind == SavedSessionMetadataProjectionKind.legacy;
  bool get isRejectedUrl =>
      kind == SavedSessionMetadataProjectionKind.rejectedUrl;
  bool get isAbsent => kind == SavedSessionMetadataProjectionKind.absent;
}
