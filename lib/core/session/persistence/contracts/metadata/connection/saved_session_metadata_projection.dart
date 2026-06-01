/// Replayable projection of one saved-session metadata value.
///
/// This keeps the decision shape shared across base URL and websocket metadata:
/// a raw value is either absent, transformed to durable reconnect metadata,
/// preserved as legacy text, or rejected because it is URL-shaped but unsafe.
class SavedSessionMetadataProjection {
  const SavedSessionMetadataProjection._({
    required this.durableValue,
    required this.isLegacyText,
    required this.isRejectedUrl,
  });

  const SavedSessionMetadataProjection.absent()
    : this._(durableValue: null, isLegacyText: false, isRejectedUrl: false);

  const SavedSessionMetadataProjection.durable(this.durableValue)
    : isLegacyText = false,
      isRejectedUrl = false;

  const SavedSessionMetadataProjection.legacy(this.durableValue)
    : isLegacyText = true,
      isRejectedUrl = false;

  const SavedSessionMetadataProjection.rejectedUrl()
    : this._(durableValue: null, isLegacyText: false, isRejectedUrl: true);

  final String? durableValue;
  final bool isLegacyText;
  final bool isRejectedUrl;

  bool get isAbsent => durableValue == null && !isRejectedUrl;
}
