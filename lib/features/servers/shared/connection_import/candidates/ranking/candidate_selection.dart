part of '../../parser.dart';

typedef _ConnectionImportCandidatePreference<T> =
    bool Function(T candidate, T? currentBest);

T? _selectPreferredConnectionImportCandidate<T>(
  Iterable<T> candidates, {
  required _ConnectionImportCandidatePreference<T> isPreferred,
}) {
  T? bestCandidate;
  for (final candidate in candidates) {
    if (isPreferred(candidate, bestCandidate)) {
      bestCandidate = candidate;
    }
  }
  return bestCandidate;
}
