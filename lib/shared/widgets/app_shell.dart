import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_shell_presentation.dart';
import 'sheet_presenter.dart';

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
          mobileNavigationDestinations:
              presentation.mobileNavigationDestinations,
          mobileOverflowDestinations: presentation.mobileOverflowDestinations,
          selectedIndex: presentation.selectedMobileIndex,
          selectedPath: presentation.selectedDestination.path,
          showNavigationMenu: presentation.showNavigationMenu,
          mobileOverflowLabel: _appShellPresentation.mobileOverflowLabel,
          mobileOverflowTooltip: _appShellPresentation.mobileOverflowTooltip,
          onSelected: (destination) => context.go(destination.path),
          child: child,
        );
      },
    );
  }
}

class _MobileShell extends StatelessWidget {
  const _MobileShell({
    required this.child,
    required this.mobileNavigationDestinations,
    required this.mobileOverflowDestinations,
    required this.selectedIndex,
    required this.selectedPath,
    required this.showNavigationMenu,
    required this.mobileOverflowLabel,
    required this.mobileOverflowTooltip,
    required this.onSelected,
  });

  final Widget child;
  final List<AppShellDestination> mobileNavigationDestinations;
  final List<AppShellDestination> mobileOverflowDestinations;
  final int selectedIndex;
  final String selectedPath;
  final bool showNavigationMenu;
  final String mobileOverflowLabel;
  final String mobileOverflowTooltip;
  final ValueChanged<AppShellDestination> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: child,
      bottomNavigationBar: showNavigationMenu
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: NavigationBarTheme(
                  data: NavigationBarThemeData(
                    backgroundColor: colorScheme.surfaceContainerHigh,
                    indicatorColor: colorScheme.primary.withValues(alpha: 0.16),
                    labelTextStyle: WidgetStateProperty.resolveWith((states) {
                      final selected = states.contains(WidgetState.selected);
                      return theme.textTheme.labelSmall?.copyWith(
                        color: selected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        fontWeight: selected ? FontWeight.w700 : null,
                      );
                    }),
                    iconTheme: WidgetStateProperty.resolveWith((states) {
                      final selected = states.contains(WidgetState.selected);
                      return IconThemeData(
                        color: selected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      );
                    }),
                  ),
                  child: NavigationBar(
                    height: 68,
                    elevation: 0,
                    selectedIndex: selectedIndex,
                    labelBehavior:
                        NavigationDestinationLabelBehavior.alwaysShow,
                    onDestinationSelected: (index) {
                      if (index < mobileNavigationDestinations.length) {
                        onSelected(mobileNavigationDestinations[index]);
                        return;
                      }
                      _showOverflowMenu(context);
                    },
                    destinations: [
                      for (final destination in mobileNavigationDestinations)
                        NavigationDestination(
                          icon: Icon(destination.icon),
                          label: destination.label,
                        ),
                      NavigationDestination(
                        icon: const Icon(Icons.more_horiz),
                        label: mobileOverflowLabel,
                        tooltip: mobileOverflowTooltip,
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }

  void _showOverflowMenu(BuildContext context) {
    showSheet(
      context,
      ActionSheet(
        _appShellPresentation.mobileOverflowLabel,
        rows: [
          for (final destination in mobileOverflowDestinations)
            SheetActionRow(
              destination.icon,
              destination.label,
              onTap: (sheetContext) {
                Navigator.of(sheetContext).pop();
                onSelected(destination);
              },
            ),
        ],
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
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
