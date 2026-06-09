/// A pending approval request issued by the server while a tool call is mid-
/// flight. The user resolves it via NavivoxChannel.respondToApproval.
class NavivoxApprovalRequest {
  const NavivoxApprovalRequest({
    required this.id,
    required this.toolCallId,
    required this.prompt,
    this.risk,
  });

  final String id;
  final String toolCallId;
  final String prompt;
  final String? risk;
}
