import '../../../gateway/messages/navivox_gateway_event.dart';
import '../../../protocol/navivox_event.dart';
import '../../contracts/navivox_channel.dart';
import '../../contracts/navivox_profile_contact_codec.dart';
import '../approvals/gateway_approval_notice.dart';
import '../messages/gateway_assistant_message_policy.dart';
import '../messages/gateway_message_scope_policy.dart';
import '../messages/gateway_safety_notice_policy.dart';
import '../messages/gateway_tool_call_policy.dart';

/// Reduces gateway stream events into explicit channel runtime effects.
///
/// The reducer is pure apart from supplied id/time callbacks. The runtime keeps
/// WebSocket listening, ChangeNotifier notifications, and approval stream side
/// effects.
GatewayEventReduction navivoxReduceGatewayEvent({
  required NavivoxGatewayEvent event,
  required NavivoxChannelState state,
  required String Function() fallbackId,
  required DateTime Function() clock,
}) {
  switch (event.type) {
    case 'pong':
    case 'gateway_identity':
    case 'done':
      return const GatewayEventReduction.ignore();
    case 'session_started':
      return GatewayEventReduction.updateActiveSession(event.sessionId);
    case 'assistant_delta':
      return _assistantReduction(
        event: event,
        state: state,
        fallbackId: fallbackId,
        clock: clock,
        appendText: true,
      );
    case 'assistant_message':
      return _assistantReduction(
        event: event,
        state: state,
        fallbackId: fallbackId,
        clock: clock,
        appendText: false,
      );
    case 'tool_call_started':
      return _toolCallReduction(
        event: event,
        state: state,
        fallbackId: fallbackId,
        clock: clock,
        status: 'started',
      );
    case 'tool_call_updated':
      return _toolCallReduction(
        event: event,
        state: state,
        fallbackId: fallbackId,
        clock: clock,
        status: event.status ?? 'updated',
      );
    case 'tool_call_finished':
      return _toolCallReduction(
        event: event,
        state: state,
        fallbackId: fallbackId,
        clock: clock,
        status: event.status ?? 'finished',
      );
    case 'safety_warning':
      return GatewayEventReduction.putMessage(
        navivoxGatewaySafetyWarningMessage(
          event: event,
          id: event.safetyId ?? 'safety-${fallbackId()}',
          createdAt: clock(),
          scope: navivoxGatewayMessageScopeFromEvent(
            event: event,
            messages: state.messages,
          ),
        ),
      );
    case 'approval_required':
      final notice = navivoxGatewayApprovalNotice(
        event: event,
        fallbackApprovalId: () => 'approval-${fallbackId()}',
      );
      final scope = navivoxGatewayMessageScopeFromEvent(
        event: event,
        messages: state.messages,
      );
      final messages = <NavivoxChatMessage>[];
      final toolApprovalMessage = navivoxGatewayToolApprovalMessage(
        id: notice.toolCallId,
        event: event,
        priorMessage: state.messages[notice.toolCallId],
        notice: notice,
        createdAt: clock(),
        scope: scope,
      );
      if (toolApprovalMessage != null) messages.add(toolApprovalMessage);
      messages.add(
        navivoxGatewayApprovalRequestMessage(
          event: event,
          notice: notice,
          createdAt: clock(),
          scope: scope,
        ),
      );
      return GatewayEventReduction.approval(messages: messages, notice: notice);
    case 'profile_contact_update':
      final contact = event.contact;
      if (contact == null) return const GatewayEventReduction.ignore();
      return GatewayEventReduction.upsertProfileContact(
        navivoxProfileContactFromJson(contact),
      );
    case 'error':
      return GatewayEventReduction.appendSystemMessage(
        event.message ?? 'Gateway error',
      );
    default:
      return const GatewayEventReduction.ignore();
  }
}

GatewayEventReduction _assistantReduction({
  required NavivoxGatewayEvent event,
  required NavivoxChannelState state,
  required String Function() fallbackId,
  required DateTime Function() clock,
  required bool appendText,
}) {
  final messageId = navivoxGatewayAssistantMessageId(
    event: event,
    fallbackRequestId: fallbackId,
  );
  return GatewayEventReduction.putMessage(
    navivoxGatewayAssistantTextMessage(
      id: messageId,
      event: event,
      existing: state.messages[messageId],
      createdAt: clock(),
      scope: navivoxGatewayMessageScopeFromEvent(
        event: event,
        messages: state.messages,
      ),
      appendText: appendText,
    ),
  );
}

GatewayEventReduction _toolCallReduction({
  required NavivoxGatewayEvent event,
  required NavivoxChannelState state,
  required String Function() fallbackId,
  required DateTime Function() clock,
  required String status,
}) {
  final toolCallId = event.toolCallId ?? 'tool-${fallbackId()}';
  return GatewayEventReduction.putMessage(
    navivoxGatewayToolCallMessage(
      id: toolCallId,
      event: event,
      status: status,
      priorMessage: state.messages[toolCallId],
      createdAt: clock(),
      scope: navivoxGatewayMessageScopeFromEvent(
        event: event,
        messages: state.messages,
      ),
    ),
  );
}

sealed class GatewayEventReduction {
  const GatewayEventReduction._();

  const factory GatewayEventReduction.ignore() = IgnoreGatewayEvent;

  const factory GatewayEventReduction.updateActiveSession(String? sessionId) =
      UpdateGatewayActiveSession;

  const factory GatewayEventReduction.putMessage(NavivoxChatMessage message) =
      PutGatewayEventMessage;

  const factory GatewayEventReduction.approval({
    required List<NavivoxChatMessage> messages,
    required NavivoxGatewayApprovalNotice notice,
  }) = PutGatewayApprovalEvent;

  const factory GatewayEventReduction.upsertProfileContact(
    NavivoxProfileContact contact,
  ) = UpsertGatewayProfileContact;

  const factory GatewayEventReduction.appendSystemMessage(String text) =
      AppendGatewaySystemMessage;
}

final class IgnoreGatewayEvent extends GatewayEventReduction {
  const IgnoreGatewayEvent() : super._();
}

final class UpdateGatewayActiveSession extends GatewayEventReduction {
  const UpdateGatewayActiveSession(this.sessionId) : super._();

  final String? sessionId;
}

final class PutGatewayEventMessage extends GatewayEventReduction {
  const PutGatewayEventMessage(this.message) : super._();

  final NavivoxChatMessage message;
}

final class PutGatewayApprovalEvent extends GatewayEventReduction {
  const PutGatewayApprovalEvent({required this.messages, required this.notice})
    : super._();

  final List<NavivoxChatMessage> messages;
  final NavivoxGatewayApprovalNotice notice;
}

final class UpsertGatewayProfileContact extends GatewayEventReduction {
  const UpsertGatewayProfileContact(this.contact) : super._();

  final NavivoxProfileContact contact;
}

final class AppendGatewaySystemMessage extends GatewayEventReduction {
  const AppendGatewaySystemMessage(this.text) : super._();

  final String text;
}
