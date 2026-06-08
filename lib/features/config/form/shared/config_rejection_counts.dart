/// Counts config form parser/planner rejections by reason.
///
/// The form schema and section planners expose small diagnostics objects with
/// different enum types, but their public count helpers all share the same
/// "count rejections matching this reason" contract.
int countConfigFormRejectionsByReason<TRejection, TReason>({
  required Iterable<TRejection> rejections,
  required TReason reason,
  required TReason Function(TRejection rejection) reasonOf,
}) {
  return rejections.where((rejection) => reasonOf(rejection) == reason).length;
}
