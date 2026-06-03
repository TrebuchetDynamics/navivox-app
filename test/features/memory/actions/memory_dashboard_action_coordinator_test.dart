import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/protocol/navivox_memory.dart';
import 'package:navivox/features/memory/actions/memory_dashboard_action_coordinator.dart';

void main() {
  const coordinator = MemoryDashboardActionCoordinator();
  const contact = NavivoxProfileContact(
    serverId: 'gateway-1',
    profileId: 'profile-1',
    displayName: 'Profile 1',
    serverLabel: 'Gateway 1',
    health: NavivoxProfileHealth.online,
    latestPreview: 'Ready',
  );

  test('search request trims query and scopes to active profile contact', () {
    final request = coordinator.searchRequest(
      activeProfile: contact,
      query: '  deploy notes  ',
      type: NavivoxMemoryType.observations,
    );

    expect(request.scope.serverId, 'gateway-1');
    expect(request.scope.profileId, 'profile-1');
    expect(request.query, 'deploy notes');
    expect(request.type, NavivoxMemoryType.observations);
    expect(request.limit, 20);
  });

  test('detail request preserves selected memory identity', () {
    const item = NavivoxMemoryItem(
      id: 'mem-1',
      type: NavivoxMemoryType.conclusions,
      snippet: 'Use fixture gateway.',
    );

    final request = coordinator.detailRequest(
      activeProfile: contact,
      item: item,
    );

    expect(request.scope.serverId, 'gateway-1');
    expect(request.id, 'mem-1');
    expect(request.type, NavivoxMemoryType.conclusions);
  });

  test('action request trims correction text', () {
    const detail = NavivoxMemoryDetail(
      id: 'mem-1',
      type: NavivoxMemoryType.memoryItems,
      content: 'Old memory',
    );

    final request = coordinator.actionRequest(
      activeProfile: contact,
      item: detail,
      action: NavivoxMemoryActionType.addCorrection,
      correction: '  safer wording  ',
    );

    expect(request.action, NavivoxMemoryActionType.addCorrection);
    expect(request.correction, 'safer wording');
  });

  test('action result maps to snackbar effect through presentation copy', () {
    final effect = coordinator.afterAction(
      const NavivoxMemoryActionResult(
        accepted: true,
        action: NavivoxMemoryActionType.archive,
        message: 'Archived',
      ),
      requestedAction: NavivoxMemoryActionType.archive,
      messageFor: (result, {required requestedAction}) =>
          '${requestedAction.label}: ${result.message}',
    );

    expect(effect, isA<ShowMemorySnackbarEffect>());
    expect((effect as ShowMemorySnackbarEffect).message, 'Archive: Archived');
  });
}
