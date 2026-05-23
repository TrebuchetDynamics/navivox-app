import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/router/app_routes.dart';
import 'package:navivox/shared/widgets/app_shell_presentation.dart';

void main() {
  const presentation = AppShellPresentation();

  test(
    'centralizes App shell destination order, routes, labels, and icons',
    () {
      final destinations = presentation.destinations;

      expect(destinations.map((destination) => destination.path), [
        AppRoutes.chats,
        AppRoutes.servers,
        AppRoutes.agents,
        AppRoutes.memory,
        AppRoutes.config,
        AppRoutes.settings,
      ]);
      expect(destinations.map((destination) => destination.label), [
        'Chats',
        'Servers',
        'Agents',
        'Memory',
        'Config',
        'Settings',
      ]);
      expect(destinations.first.icon, Icons.chat_bubble_outlined);
      expect(destinations.last.icon, Icons.keyboard_voice_outlined);
    },
  );

  test('selects destination by location with Chats as safe fallback', () {
    expect(
      presentation.stateForLocation(AppRoutes.memory).selectedDestination.label,
      'Memory',
    );
    expect(
      presentation
          .stateForLocation('/config/providers')
          .selectedDestination
          .label,
      'Config',
    );
    expect(
      presentation.stateForLocation('/unknown').selectedDestination.label,
      'Chats',
    );
  });

  test('hides mobile navigation menu only on Profile contact chat threads', () {
    expect(
      presentation.stateForLocation('/chats/local/mineru').showNavigationMenu,
      isFalse,
    );
    expect(
      presentation.stateForLocation(AppRoutes.chats).showNavigationMenu,
      isTrue,
    );
    expect(
      presentation.stateForLocation(AppRoutes.servers).showNavigationMenu,
      isTrue,
    );
  });

  test('centralizes drawer header and menu affordance copy', () {
    expect(presentation.navigationMenuTooltip, 'Open navigation menu');
    expect(presentation.drawerHeaderTitle, 'Navivox');
    expect(presentation.drawerHeaderSubtitle, 'Gormes operator console');
  });
}
