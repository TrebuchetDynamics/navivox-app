/// Default maximum age for saved reconnect metadata before it is considered stale.
const savedSessionStaleAfter = Duration(days: 7);

/// Returns whether saved connection metadata is too old to trust for reconnect UI.
bool isSavedSessionStale({
  required DateTime? lastConnectedAt,
  required DateTime now,
}) {
  if (lastConnectedAt == null) return true;
  return now.toUtc().difference(lastConnectedAt.toUtc()) >
      savedSessionStaleAfter;
}
