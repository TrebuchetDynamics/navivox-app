import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';

import '../../../../support/test_navivox_channel.dart';

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

/// Asserts the channel selected the same scope as [contact].
void expectSelectedProfileContactScope(
  TestNavivoxChannel channel,
  NavivoxProfileContact contact,
) {
  expectSelectedProfileScope(
    channel,
    serverId: contact.serverId,
    profileId: contact.profileId,
  );
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

/// Asserts the last text send was routed to [contact].
void expectLastSentTextToProfileContact(
  TestNavivoxChannel channel, {
  required String text,
  required NavivoxProfileContact contact,
}) {
  expectLastSentTextCall(
    channel,
    text: text,
    serverId: contact.serverId,
    profileId: contact.profileId,
  );
}
