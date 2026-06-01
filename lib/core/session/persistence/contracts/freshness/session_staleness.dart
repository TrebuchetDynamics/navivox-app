/// Default maximum age for saved reconnect metadata before it is considered stale.
const savedSessionStaleAfter = Duration(days: 7);

/// Returns the persisted session age in UTC time.
///
/// A negative duration means the saved timestamp is ahead of [now], which can
/// happen after clock changes or corrupt persisted metadata.
Duration? savedSessionConnectionAge({
  required DateTime? lastConnectedAt,
  required DateTime now,
}) {
  if (lastConnectedAt == null) return null;
  return now.toUtc().difference(lastConnectedAt.toUtc());
}

/// Returns whether saved connection metadata is too old to trust for reconnect UI.
bool isSavedSessionStale({
  required DateTime? lastConnectedAt,
  required DateTime now,
}) {
  final age = savedSessionConnectionAge(
    lastConnectedAt: lastConnectedAt,
    now: now,
  );
  if (age == null) return true;
  if (age.isNegative) return true;
  return age > savedSessionStaleAfter;
}
