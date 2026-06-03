import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/gateway/events/gateway_event_reducer.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/gateway/messages/navivox_gateway_event.dart';
import 'package:navivox/core/protocol/navivox_event.dart';

void main() {
  final clockTime = DateTime.utc(2026, 1, 2, 3, 4, 5);
  var id = 0;
  String nextId() => 'id-${++id}';

  GatewayEventReduction reduce(
    NavivoxGatewayEvent event, {
    NavivoxChannelState state = const NavivoxChannelState(),
  }) {
    return navivoxReduceGatewayEvent(
      event: event,
      state: state,
      fallbackId: nextId,
      clock: () => clockTime,
    );
  }

  setUp(() => id = 0);

  test('assistant message keeps profile scope and run record reference', () {
    final reduction = reduce(
      const NavivoxGatewayEvent(
        type: 'assistant_message',
        requestId: 'request-1',
        text: 'hello from gateway',
        runRecordReference: 'run-1',
        metadata: {'server_id': 'server-a', 'profile_id': 'profile-a'},
      ),
    );

    expect(reduction, isA<PutGatewayEventMessage>());
    final message = (reduction as PutGatewayEventMessage).message;
    expect(message.id, 'assistant-request-1');
    expect(message.author, NavivoxMessageAuthor.assistant);
    expect(message.text, 'hello from gateway');
    expect(message.serverId, 'server-a');
    expect(message.profileId, 'profile-a');
    expect(message.runRecordReference, 'run-1');
  });

  test('assistant delta appends to existing scoped message text', () {
    final state = NavivoxChannelState(
      messages: {
        'assistant-request-1': NavivoxChatMessage(
          id: 'assistant-request-1',
          author: NavivoxMessageAuthor.assistant,
          kind: NavivoxMessageKind.text,
          createdAt: clockTime,
          text: 'hello',
          serverId: 'server-a',
          profileId: 'profile-a',
        ),
      },
    );

    final reduction = reduce(
      const NavivoxGatewayEvent(
        type: 'assistant_delta',
        requestId: 'request-1',
        text: ' world',
      ),
      state: state,
    );

    final message = (reduction as PutGatewayEventMessage).message;
    expect(message.text, 'hello world');
    expect(message.serverId, 'server-a');
    expect(message.profileId, 'profile-a');
  });

  test('tool call upserts by tool call id and status', () {
    final reduction = reduce(
      const NavivoxGatewayEvent(
        type: 'tool_call_finished',
        toolCallId: 'tool-1',
        toolName: 'grep',
        status: 'completed',
        message: 'Found matches',
        metadata: {'server_id': 'server-a', 'profile_id': 'profile-a'},
      ),
    );

    final message = (reduction as PutGatewayEventMessage).message;
    expect(message.id, 'tool-1');
    expect(message.kind, NavivoxMessageKind.toolCall);
    expect(message.toolCall?.name, 'grep');
    expect(message.toolCall?.status, 'completed');
    expect(message.serverId, 'server-a');
    expect(message.profileId, 'profile-a');
  });

  test('approval event emits approval messages and notice', () {
    final reduction = reduce(
      const NavivoxGatewayEvent(
        type: 'approval_required',
        toolCallId: 'tool-1',
        approvalId: 'approval-1',
        message: 'Allow tool?',
        risk: 'high',
      ),
    );

    expect(reduction, isA<PutGatewayApprovalEvent>());
    final approval = reduction as PutGatewayApprovalEvent;
    expect(approval.notice.id, 'approval-1');
    expect(approval.notice.toolCallId, 'tool-1');
    expect(
      approval.messages.map((message) => message.kind),
      contains(NavivoxMessageKind.approvalRequest),
    );
  });

  test('profile contact update is a typed upsert effect', () {
    final reduction = reduce(
      const NavivoxGatewayEvent(
        type: 'profile_contact_update',
        contact: {
          'server_id': 'server-a',
          'profile_id': 'profile-a',
          'display_name': 'Profile A',
          'server_label': 'Gateway A',
          'health': 'online',
          'latest_preview': 'Ready',
        },
      ),
    );

    expect(reduction, isA<UpsertGatewayProfileContact>());
    final contact = (reduction as UpsertGatewayProfileContact).contact;
    expect(contact.serverId, 'server-a');
    expect(contact.profileId, 'profile-a');
    expect(contact.displayName, 'Profile A');
  });

  test(
    'error becomes a bounded system-message effect and ignored events stay ignored',
    () {
      expect(
        reduce(
          const NavivoxGatewayEvent(type: 'error', message: 'Gateway boom'),
        ),
        isA<AppendGatewaySystemMessage>().having(
          (effect) => effect.text,
          'text',
          'Gateway boom',
        ),
      );
      expect(
        reduce(const NavivoxGatewayEvent(type: 'pong')),
        isA<IgnoreGatewayEvent>(),
      );
      expect(
        reduce(const NavivoxGatewayEvent(type: 'unknown')),
        isA<IgnoreGatewayEvent>(),
      );
    },
  );
}
