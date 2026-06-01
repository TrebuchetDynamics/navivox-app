import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/chat/approval/approval_banner.dart';

import '../../shared/app/test_material_app.dart';
import '../../../support/test_navivox_channel.dart';
import 'shared/approval_banner_widget_test_fixtures.dart';
import 'shared/approval_request_test_fixtures.dart';

void main() {
  testWidgets(
    'shows the prompt and resolves Allow into respondToApproval(true)',
    (tester) async {
      final channel = await pumpApprovalBanner(tester);

      expect(find.byType(ApprovalBanner), findsOneWidget);
      expect(find.text('Allow'), findsNothing);

      channel.emitApprovalRequest(
        approvalRequest(
          id: 'ap-1',
          toolCallId: 'tc-1',
          prompt: 'Allow shell.run to delete /tmp/x?',
          risk: 'medium',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('shell.run'), findsOneWidget);
      expect(find.text('Allow'), findsOneWidget);
      expect(find.text('Deny'), findsOneWidget);

      await tester.tap(find.text('Allow'));
      await tester.pumpAndSettle();

      expect(channel.approvalResponses.length, 1);
      expect(channel.approvalResponses.single.approvalId, 'ap-1');
      expect(channel.approvalResponses.single.approved, isTrue);
      // Banner clears after the response is sent.
      expect(find.text('Allow'), findsNothing);
    },
  );

  testWidgets('Deny calls respondToApproval(false)', (tester) async {
    final channel = await pumpApprovalBanner(tester);

    channel.emitApprovalRequest(
      approvalRequest(
        id: 'ap-2',
        toolCallId: 'tc-2',
        prompt: 'Allow shell.run?',
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Deny'));
    await tester.pumpAndSettle();

    expect(channel.approvalResponses.single.approved, isFalse);
  });

  testWidgets('resubscribes when the banner channel changes', (tester) async {
    final oldChannel = TestNavivoxChannel();
    final newChannel = TestNavivoxChannel();

    await tester.pumpWidget(
      TestMaterialScaffold(body: ApprovalBanner(channel: oldChannel)),
    );
    oldChannel.emitApprovalRequest(
      approvalRequest(
        id: 'old-approval',
        toolCallId: 'tc-old',
        prompt: 'Old channel approval?',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Old channel approval?'), findsOneWidget);

    await tester.pumpWidget(
      TestMaterialScaffold(body: ApprovalBanner(channel: newChannel)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Old channel approval?'), findsNothing);

    oldChannel.emitApprovalRequest(
      approvalRequest(
        id: 'stale-approval',
        toolCallId: 'tc-stale',
        prompt: 'Stale channel approval?',
      ),
    );
    newChannel.emitApprovalRequest(
      approvalRequest(
        id: 'new-approval',
        toolCallId: 'tc-new',
        prompt: 'New channel approval?',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Stale channel approval?'), findsNothing);
    expect(find.text('New channel approval?'), findsOneWidget);
  });
}
