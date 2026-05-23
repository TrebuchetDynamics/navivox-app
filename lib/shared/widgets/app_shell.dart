import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_shell_presentation.dart';

const _appShellPresentation = AppShellPresentation();

class AppShell extends StatelessWidget {
  const AppShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final presentation = _appShellPresentation.stateForLocation(location);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          return _DesktopShell(
            destinations: presentation.destinations,
            selectedIndex: presentation.selectedIndex,
            onSelected: (index) =>
                context.go(presentation.destinations[index].path),
            child: child,
          );
        }
        return _MobileShell(
          destinations: presentation.destinations,
          selectedIndex: presentation.selectedIndex,
          showNavigationMenu: presentation.showNavigationMenu,
          navigationMenuTooltip: _appShellPresentation.navigationMenuTooltip,
          drawerHeaderTitle: _appShellPresentation.drawerHeaderTitle,
          drawerHeaderSubtitle: _appShellPresentation.drawerHeaderSubtitle,
          onSelected: (index) =>
              context.go(presentation.destinations[index].path),
          child: child,
        );
      },
    );
  }
}

class _MobileShell extends StatelessWidget {
  const _MobileShell({
    required this.child,
    required this.destinations,
    required this.selectedIndex,
    required this.showNavigationMenu,
    required this.navigationMenuTooltip,
    required this.drawerHeaderTitle,
    required this.drawerHeaderSubtitle,
    required this.onSelected,
  });

  final Widget child;
  final List<AppShellDestination> destinations;
  final int selectedIndex;
  final bool showNavigationMenu;
  final String navigationMenuTooltip;
  final String drawerHeaderTitle;
  final String drawerHeaderSubtitle;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      drawer: showNavigationMenu
          ? _AppNavigationDrawer(
              destinations: destinations,
              selectedIndex: selectedIndex,
              drawerHeaderTitle: drawerHeaderTitle,
              drawerHeaderSubtitle: drawerHeaderSubtitle,
              onSelected: onSelected,
            )
          : null,
      floatingActionButton: showNavigationMenu
          ? Builder(
              builder: (context) => FloatingActionButton.small(
                heroTag: 'navivox-navigation-menu',
                tooltip: navigationMenuTooltip,
                backgroundColor: colorScheme.surface,
                foregroundColor: colorScheme.primary,
                elevation: 0,
                highlightElevation: 0,
                shape: const CircleBorder(),
                onPressed: () => Scaffold.of(context).openDrawer(),
                child: const Icon(Icons.menu),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      body: child,
    );
  }
}

class _AppNavigationDrawer extends StatelessWidget {
  const _AppNavigationDrawer({
    required this.destinations,
    required this.selectedIndex,
    required this.drawerHeaderTitle,
    required this.drawerHeaderSubtitle,
    required this.onSelected,
  });

  final List<AppShellDestination> destinations;
  final int selectedIndex;
  final String drawerHeaderTitle;
  final String drawerHeaderSubtitle;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              margin: EdgeInsets.zero,
              decoration: BoxDecoration(color: colorScheme.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    backgroundColor: colorScheme.onPrimary.withAlpha(32),
                    child: Icon(
                      Icons.smart_toy_outlined,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    drawerHeaderTitle,
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    drawerHeaderSubtitle,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            for (var index = 0; index < destinations.length; index++)
              ListTile(
                leading: Icon(destinations[index].icon),
                title: Text(destinations[index].label),
                selected: index == selectedIndex,
                onTap: () {
                  Navigator.of(context).pop();
                  onSelected(index);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _DesktopShell extends StatelessWidget {
  const _DesktopShell({
    required this.child,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final Widget child;
  final List<AppShellDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onSelected,
            extended: true,
            destinations: [
              for (final d in destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Container(
              color: theme.colorScheme.surfaceContainerLowest,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
