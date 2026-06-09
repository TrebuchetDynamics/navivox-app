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

  group('gateway stream projection', () {
    test(
      'resolves scope from metadata before existing transcript messages',
      () {
        final requestMessage = NavivoxChatMessage(
          id: 'request-1',
          author: NavivoxMessageAuthor.user,
          kind: NavivoxMessageKind.text,
          createdAt: DateTime.utc(2026),
          serverId: 'request-server',
          profileId: 'request-profile',
        );

        final reduction = reduce(
          const NavivoxGatewayEvent(
            type: 'assistant_delta',
            requestId: 'request-1',
            text: 'Hello',
            metadata: {
              'server_id': 'metadata-server',
              'profile_id': 'metadata-profile',
            },
          ),
          state: NavivoxChannelState(messages: {'request-1': requestMessage}),
        );

        final message = (reduction as PutGatewayEventMessage).message;
        expect(message.serverId, 'metadata-server');
        expect(message.profileId, 'metadata-profile');
      },
    );

    test('assistant updates preserve prior scope and merge run records', () {
      final createdAt = DateTime.utc(2026, 1, 1);
      final prior = NavivoxChatMessage(
        id: 'assistant-request-1',
        author: NavivoxMessageAuthor.assistant,
        kind: NavivoxMessageKind.text,
        createdAt: createdAt,
        text: 'Hel',
        runRecordReference: 'run-prior',
        serverId: 'prior-server',
        profileId: 'prior-profile',
      );

      final reduction = reduce(
        const NavivoxGatewayEvent(
          type: 'assistant_delta',
          requestId: 'request-1',
          text: 'lo',
          runRecordReference: 'run-next',
          metadata: {
            'server_id': 'event-server',
            'profile_id': 'event-profile',
          },
        ),
        state: NavivoxChannelState(messages: {prior.id: prior}),
      );

      final message = (reduction as PutGatewayEventMessage).message;
      expect(message.text, 'Hello');
      expect(message.createdAt, createdAt);
      expect(message.runRecordReference, 'run-next');
      expect(message.serverId, 'prior-server');
      expect(message.profileId, 'prior-profile');
    });

    test(
      'tool approval updates preserve the tool card and attach approval',
      () {
        final prior = NavivoxChatMessage(
          id: 'tool-1',
          author: NavivoxMessageAuthor.assistant,
          kind: NavivoxMessageKind.toolCall,
          createdAt: DateTime.utc(2026, 1, 1),
          toolCall: const NavivoxToolCall(
            name: 'browser.open',
            status: 'waiting',
            summary: 'Open browser',
          ),
          serverId: 'prior-server',
          profileId: 'prior-profile',
        );

        final reduction = reduce(
          const NavivoxGatewayEvent(
            type: 'approval_required',
            approvalId: 'approval-1',
            toolCallId: 'tool-1',
            message: 'Allow browser open?',
            risk: 'medium',
            runRecordReference: 'run-approval',
            metadata: {
              'server_id': 'event-server',
              'profile_id': 'event-profile',
            },
          ),
          state: NavivoxChannelState(messages: {prior.id: prior}),
        );

        final approval = reduction as PutGatewayApprovalEvent;
        final message = approval.messages.firstWhere(
          (message) => message.kind == NavivoxMessageKind.toolCall,
        );
        expect(message.toolCall!.name, 'browser.open');
        expect(message.toolCall!.approval!.id, 'approval-1');
        expect(message.runRecordReference, 'run-approval');
        expect(message.serverId, 'prior-server');
        expect(message.profileId, 'prior-profile');
      },
    );

    test('safety warnings keep event severity and scoped notice payload', () {
      final reduction = reduce(
        const NavivoxGatewayEvent(
          type: 'safety_warning',
          safetyId: 'safety-1',
          severity: 'blocker',
          message: 'Stop',
          risk: 'high',
          runRecordReference: 'run-safety',
          metadata: {'server_id': 'server-1', 'profile_id': 'profile-1'},
        ),
      );

      final message = (reduction as PutGatewayEventMessage).message;
      expect(message.kind, NavivoxMessageKind.safetyWarning);
      expect(message.safetyNotice!.severity, 'blocker');
      expect(message.safetyNotice!.message, 'Stop');
      expect(message.safetyNotice!.risk, 'high');
      expect(message.runRecordReference, 'run-safety');
      expect(message.serverId, 'server-1');
      expect(message.profileId, 'profile-1');
    });
  });
}
