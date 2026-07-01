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
        AppRoutes.hermes,
        AppRoutes.chats,
        AppRoutes.servers,
        AppRoutes.agents,
        AppRoutes.memory,
        AppRoutes.config,
        AppRoutes.settings,
      ]);
      expect(destinations.map((destination) => destination.label), [
        'Hermes',
        'Chats',
        'Gateways',
        'Profiles',
        'Memory',
        'Config',
        'Settings',
      ]);
      expect(destinations.first.icon, Icons.auto_awesome_outlined);
      expect(destinations[3].icon, Icons.people_alt_outlined);
      expect(destinations.last.icon, Icons.keyboard_voice_outlined);
      expect(presentation.mobileNavigationDestinations.map((d) => d.label), [
        'Hermes',
        'Chats',
        'Profiles',
        'Settings',
      ]);
      expect(presentation.mobileOverflowDestinations.map((d) => d.label), [
        'Gateways',
        'Memory',
        'Config',
      ]);
    },
  );

  test('selects destination by location with Hermes as safe fallback', () {
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
      presentation.stateForLocation(AppRoutes.hermes).selectedDestination.label,
      'Hermes',
    );
    expect(
      presentation.stateForLocation('/unknown').selectedDestination.label,
      'Hermes',
    );
  });

  test('hides mobile navigation only on Profile contact chat threads', () {
    expect(
      presentation.stateForLocation('/chats/local/mineru').showNavigationMenu,
      isFalse,
    );
    expect(
      presentation.stateForLocation(AppRoutes.chats).showNavigationMenu,
      isTrue,
    );
    expect(
      presentation.stateForLocation('/chats/local').showNavigationMenu,
      isTrue,
    );
    expect(
      presentation.stateForLocation(AppRoutes.servers).showNavigationMenu,
      isTrue,
    );
  });

  test('centralizes bottom nav overflow copy', () {
    expect(presentation.navigationMenuTooltip, 'Open navigation menu');
    expect(presentation.mobileOverflowLabel, 'More');
    expect(presentation.mobileOverflowTooltip, 'Open more destinations');
  });

  test('maps overflow routes to the More tab on mobile', () {
    expect(
      presentation.stateForLocation(AppRoutes.config).selectedMobileIndex,
      4,
    );
    expect(
      presentation.stateForLocation(AppRoutes.servers).selectedMobileIndex,
      4,
    );
    expect(
      presentation.stateForLocation(AppRoutes.memory).selectedMobileIndex,
      4,
    );
    expect(
      presentation.stateForLocation(AppRoutes.hermes).selectedMobileIndex,
      0,
    );
  });
}
