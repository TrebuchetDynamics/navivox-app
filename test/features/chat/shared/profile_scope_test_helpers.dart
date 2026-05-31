import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_navivox_channel.dart';

/// Asserts the chat channel selected the expected Profile-scoped conversation.
void expectSelectedProfileScope(
  TestNavivoxChannel channel, {
  required String serverId,
  required String profileId,
}) {
  expect(channel.selectedProfileScope, (
    serverId: serverId,
    profileId: profileId,
  ));
}

/// Asserts the last text send was routed to the expected Profile scope.
void expectLastSentTextCall(
  TestNavivoxChannel channel, {
  required String text,
  required String serverId,
  required String profileId,
}) {
  expect(channel.sentTextCalls.last, (
    text: text,
    serverId: serverId,
    profileId: profileId,
  ));
}
