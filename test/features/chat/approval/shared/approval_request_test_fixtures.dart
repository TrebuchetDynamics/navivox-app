import 'package:navivox/core/channel/navivox_channel.dart';

/// Shared Approval request fixture for banner presentation and widget tests.
NavivoxApprovalRequest approvalRequest({
  required String id,
  required String toolCallId,
  required String prompt,
  String? risk,
}) {
  return NavivoxApprovalRequest(
    id: id,
    toolCallId: toolCallId,
    prompt: prompt,
    risk: risk,
  );
}
