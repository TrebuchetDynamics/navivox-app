import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/chat/approval/approval_banner.dart';

import '../../../../support/test_navivox_channel.dart';
import '../../../shared/app/test_material_app.dart';

/// Pumps the Approval banner in its shared Material test shell.
Future<TestNavivoxChannel> pumpApprovalBanner(WidgetTester tester) async {
  final channel = TestNavivoxChannel();

  await tester.pumpWidget(
    TestMaterialScaffold(body: ApprovalBanner(channel: channel)),
  );

  return channel;
}
