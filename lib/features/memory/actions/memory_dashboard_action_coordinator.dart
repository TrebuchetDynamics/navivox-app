import '../../../core/channel/navivox_channel.dart';
import '../../../core/protocol/navivox_memory.dart';

/// Coordinates memory dashboard scope and action requests.
///
/// The dashboard widgets still own Riverpod, FutureBuilder, dialogs, sheets,
/// channel calls, and SnackBar rendering.
final class MemoryDashboardActionCoordinator {
  const MemoryDashboardActionCoordinator();

  MemoryScope scopeFor(NavivoxProfileContact? activeProfile) {
    return MemoryScope(
      serverId: activeProfile?.serverId,
      profileId: activeProfile?.profileId,
    );
  }

  MemorySearchRequest searchRequest({
    required NavivoxProfileContact? activeProfile,
    required String query,
    required NavivoxMemoryType type,
    int limit = 20,
  }) {
    final scope = scopeFor(activeProfile);
    return MemorySearchRequest(
      scope: scope,
      query: query.trim(),
      type: type,
      limit: limit,
    );
  }

  MemoryDetailRequest detailRequest({
    required NavivoxProfileContact? activeProfile,
    required NavivoxMemoryItem item,
  }) {
    return MemoryDetailRequest(
      scope: scopeFor(activeProfile),
      id: item.id,
      type: item.type,
    );
  }

  MemoryActionRequest actionRequest({
    required NavivoxProfileContact? activeProfile,
    required NavivoxMemoryDetail item,
    required NavivoxMemoryActionType action,
    String? correction,
  }) {
    return MemoryActionRequest(
      scope: scopeFor(activeProfile),
      id: item.id,
      type: item.type,
      action: action,
      correction: correction?.trim(),
    );
  }

  MemoryActionEffect afterAction(
    NavivoxMemoryActionResult result, {
    required NavivoxMemoryActionType requestedAction,
    required String Function(
      NavivoxMemoryActionResult result, {
      required NavivoxMemoryActionType requestedAction,
    })
    messageFor,
  }) {
    return MemoryActionEffect.showSnackbar(
      messageFor(result, requestedAction: requestedAction),
    );
  }
}

final class MemoryScope {
  const MemoryScope({required this.serverId, required this.profileId});

  final String? serverId;
  final String? profileId;
}

final class MemorySearchRequest {
  const MemorySearchRequest({
    required this.scope,
    required this.query,
    required this.type,
    required this.limit,
  });

  final MemoryScope scope;
  final String query;
  final NavivoxMemoryType type;
  final int limit;
}

final class MemoryDetailRequest {
  const MemoryDetailRequest({
    required this.scope,
    required this.id,
    required this.type,
  });

  final MemoryScope scope;
  final String id;
  final NavivoxMemoryType type;
}

final class MemoryActionRequest {
  const MemoryActionRequest({
    required this.scope,
    required this.id,
    required this.type,
    required this.action,
    this.correction,
  });

  final MemoryScope scope;
  final String id;
  final NavivoxMemoryType type;
  final NavivoxMemoryActionType action;
  final String? correction;
}

sealed class MemoryActionEffect {
  const MemoryActionEffect._();

  const factory MemoryActionEffect.showSnackbar(String message) =
      ShowMemorySnackbarEffect;
}

final class ShowMemorySnackbarEffect extends MemoryActionEffect {
  const ShowMemorySnackbarEffect(this.message) : super._();

  final String message;
}
