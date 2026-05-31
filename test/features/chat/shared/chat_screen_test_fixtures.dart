import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/chat/screens/chat_screen.dart';

import '../../../support/test_navivox_channel.dart';
import '../../shared/app/test_material_app.dart';

/// Pumps the chat screen in the standard chat feature material app harness.
Future<void> pumpChatScreen(
  WidgetTester tester, {
  required TestNavivoxChannel channel,
  String? serverId,
  String? profileId,
}) {
  return tester.pumpWidget(
    TestNavivoxMaterialApp(
      channel: channel,
      home: ChatScreen(serverId: serverId, profileId: profileId),
    ),
  );
}

/// Opens the chat info bottom sheet through the shared chat context action.
Future<void> openChatInfoSheet(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('chat-context-action')));
  await tester.pumpAndSettle();

  expectChatInfoSheetOpen();
}

/// Asserts the chat info sheet is visible in chat-screen integration tests.
void expectChatInfoSheetOpen() {
  expect(find.text('Chat info'), findsOneWidget);
  expect(find.byType(DraggableScrollableSheet), findsOneWidget);
}
