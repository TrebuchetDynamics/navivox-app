import 'package:flutter/material.dart';

import '../../router/app_routes.dart';

class AppShellPresentation {
  const AppShellPresentation();

  List<AppShellDestination> get destinations => _destinations;

  String get navigationMenuTooltip => 'Open navigation menu';

  String get drawerHeaderTitle => 'Navivox';

  String get drawerHeaderSubtitle => 'Gormes operator console';

  AppShellNavigationState stateForLocation(String location) {
    final selectedIndex = destinations.indexWhere(
      (destination) => location.startsWith(destination.path),
    );
    final selected = selectedIndex < 0 ? 0 : selectedIndex;
    return AppShellNavigationState(
      destinations: destinations,
      selectedIndex: selected,
      showNavigationMenu: !AppRoutes.isChatThreadLocation(location),
    );
  }
}

class AppShellNavigationState {
  const AppShellNavigationState({
    required this.destinations,
    required this.selectedIndex,
    required this.showNavigationMenu,
  });

  final List<AppShellDestination> destinations;
  final int selectedIndex;
  final bool showNavigationMenu;

  AppShellDestination get selectedDestination => destinations[selectedIndex];
}

class AppShellDestination {
  const AppShellDestination({
    required this.path,
    required this.icon,
    required this.label,
  });

  final String path;
  final IconData icon;
  final String label;
}

const _destinations = [
  AppShellDestination(
    path: AppRoutes.chats,
    icon: Icons.chat_bubble_outlined,
    label: 'Chats',
  ),
  AppShellDestination(
    path: AppRoutes.servers,
    icon: Icons.dns_outlined,
    label: 'Servers',
  ),
  AppShellDestination(
    path: AppRoutes.agents,
    icon: Icons.smart_toy_outlined,
    label: 'Agents',
  ),
  AppShellDestination(
    path: AppRoutes.memory,
    icon: Icons.psychology_alt_outlined,
    label: 'Memory',
  ),
  AppShellDestination(
    path: AppRoutes.config,
    icon: Icons.settings_outlined,
    label: 'Config',
  ),
  AppShellDestination(
    path: AppRoutes.settings,
    icon: Icons.keyboard_voice_outlined,
    label: 'Settings',
  ),
];
