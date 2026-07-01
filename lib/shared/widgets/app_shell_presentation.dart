import 'package:flutter/material.dart';

import '../../router/app_routes.dart';

class AppShellPresentation {
  const AppShellPresentation();

  List<AppShellDestination> get destinations => _destinations;

  List<AppShellDestination> get mobileNavigationDestinations =>
      _mobileNavigationDestinations;

  List<AppShellDestination> get mobileOverflowDestinations =>
      _mobileOverflowDestinations;

  String get navigationMenuTooltip => 'Open navigation menu';

  String get mobileOverflowLabel => 'More';

  String get mobileOverflowTooltip => 'Open more destinations';

  String get drawerHeaderTitle => 'Navivox';

  String get drawerHeaderSubtitle => 'Hermes Agent mobile console';

  AppShellNavigationState stateForLocation(String location) {
    final selectedIndex = destinations.indexWhere(
      (destination) => AppRoutes.isNavigationDestinationLocation(
        location: location,
        destinationPath: destination.path,
      ),
    );
    final selected = selectedIndex < 0 ? 0 : selectedIndex;
    return AppShellNavigationState(
      destinations: destinations,
      mobileNavigationDestinations: mobileNavigationDestinations,
      mobileOverflowDestinations: mobileOverflowDestinations,
      selectedIndex: selected,
      showNavigationMenu: !AppRoutes.isChatThreadLocation(location),
    );
  }
}

class AppShellNavigationState {
  const AppShellNavigationState({
    required this.destinations,
    required this.mobileNavigationDestinations,
    required this.mobileOverflowDestinations,
    required this.selectedIndex,
    required this.showNavigationMenu,
  });

  final List<AppShellDestination> destinations;
  final List<AppShellDestination> mobileNavigationDestinations;
  final List<AppShellDestination> mobileOverflowDestinations;
  final int selectedIndex;
  final bool showNavigationMenu;

  AppShellDestination get selectedDestination => destinations[selectedIndex];

  int get selectedMobileIndex {
    final selectedPath = selectedDestination.path;
    final primaryIndex = mobileNavigationDestinations.indexWhere(
      (destination) => AppRoutes.isNavigationDestinationLocation(
        location: selectedPath,
        destinationPath: destination.path,
      ),
    );
    if (primaryIndex >= 0) return primaryIndex;
    return mobileNavigationDestinations.length;
  }
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

const _hermesDestination = AppShellDestination(
  path: AppRoutes.hermes,
  icon: Icons.auto_awesome_outlined,
  label: 'Hermes',
);
const _chatsDestination = AppShellDestination(
  path: AppRoutes.chats,
  icon: Icons.chat_bubble_outlined,
  label: 'Chats',
);
const _serversDestination = AppShellDestination(
  path: AppRoutes.servers,
  icon: Icons.dns_outlined,
  label: 'Gateways',
);
const _agentsDestination = AppShellDestination(
  path: AppRoutes.agents,
  icon: Icons.people_alt_outlined,
  label: 'Profiles',
);
const _memoryDestination = AppShellDestination(
  path: AppRoutes.memory,
  icon: Icons.psychology_alt_outlined,
  label: 'Memory',
);
const _configDestination = AppShellDestination(
  path: AppRoutes.config,
  icon: Icons.settings_outlined,
  label: 'Config',
);
const _settingsDestination = AppShellDestination(
  path: AppRoutes.settings,
  icon: Icons.keyboard_voice_outlined,
  label: 'Settings',
);

const _destinations = [
  _hermesDestination,
  _chatsDestination,
  _serversDestination,
  _agentsDestination,
  _memoryDestination,
  _configDestination,
  _settingsDestination,
];

const _mobileNavigationDestinations = [
  _hermesDestination,
  _chatsDestination,
  _agentsDestination,
  _settingsDestination,
];

const _mobileOverflowDestinations = [
  _serversDestination,
  _memoryDestination,
  _configDestination,
];
