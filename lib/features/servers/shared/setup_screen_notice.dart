/// Shared notice model used by setup UI and setup screen presentation.
class SetupScreenNotice {
  const SetupScreenNotice._({
    required this.kind,
    required this.message,
    this.recoveryMessage,
  });

  const SetupScreenNotice.info(String message)
    : this._(kind: SetupScreenNoticeKind.info, message: message);

  const SetupScreenNotice.error(String message, {String? recoveryMessage})
    : this._(
        kind: SetupScreenNoticeKind.error,
        message: message,
        recoveryMessage: recoveryMessage,
      );

  final SetupScreenNoticeKind kind;
  final String message;
  final String? recoveryMessage;

  bool get isError => kind == SetupScreenNoticeKind.error;
}

enum SetupScreenNoticeKind { info, error }
