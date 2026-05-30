import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../routes/app_routes.dart';

/// A [NavigationIntent] names the destination an operator wants to reach.
///
/// Callers use [NavigationIntent.go] or [NavigationIntent.maybeGo] instead of
/// accessing GoRouter directly. The [NavigationIntentResolver] translates
/// each variant to a GoRouter route path behind the scene.
sealed class NavigationIntent {
  const NavigationIntent._();

  /// Navigates using the GoRouter ancestor of [context].
  ///
  /// Throws if no GoRouter is found.
  static void go(BuildContext context, NavigationIntent intent) {
    GoRouter.of(context).go(_resolver.resolve(intent));
  }

  /// Like [go] but returns null instead of throwing when no GoRouter exists.
  static void maybeGo(BuildContext context, NavigationIntent intent) {
    GoRouter.maybeOf(context)?.go(_resolver.resolve(intent));
  }

  static final NavigationIntentResolver _resolver =
      NavigationIntentResolver();
}

class OpenAgents extends NavigationIntent {
  const OpenAgents() : super._();
}

class OpenWorkspace extends NavigationIntent {
  const OpenWorkspace() : super._();
}

class OpenConfig extends NavigationIntent {
  const OpenConfig() : super._();
}

class OpenSettings extends NavigationIntent {
  const OpenSettings() : super._();
}

class OpenGateways extends NavigationIntent {
  const OpenGateways() : super._();
}

class OpenChatsList extends NavigationIntent {
  const OpenChatsList() : super._();
}

class OpenChatThread extends NavigationIntent {
  final String serverId;
  final String profileId;

  const OpenChatThread(this.serverId, this.profileId) : super._();
}

/// Translates a [NavigationIntent] to a GoRouter route path.
class NavigationIntentResolver {
  const NavigationIntentResolver();

  String resolve(NavigationIntent intent) {
    return switch (intent) {
      OpenAgents() => AppRoutes.agents,
      OpenWorkspace() => AppRoutes.memory,
      OpenConfig() => AppRoutes.config,
      OpenSettings() => AppRoutes.settings,
      OpenGateways() => AppRoutes.servers,
      OpenChatsList() => AppRoutes.chats,
      OpenChatThread(:final serverId, :final profileId) =>
        AppRoutes.chatLocation(serverId: serverId, profileId: profileId),
    };
  }
}
