import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/gateway/navivox_gateway_protocol.dart';
import '../../../support/test_navivox_channel.dart';
import '../../shared/app/test_material_app.dart';
import 'package:navivox/features/config/screens/config_screen.dart';

void main() {
  testWidgets('shows empty-state message when no schema is loaded', (
    tester,
  ) async {
    final channel = TestNavivoxChannel();

    await tester.pumpWidget(
      TestNavivoxMaterialApp(channel: channel, home: const ConfigScreen()),
    );

    expect(find.text('No config available'), findsOneWidget);
  });

  testWidgets('shows active server and profile scope above config fields', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers(const [
        NavivoxServer(id: 'local', name: 'Local Gormes', status: 'online'),
      ], activeServerId: 'local')
      ..seedProfileContacts(const [
        NavivoxProfileContact(
          serverId: 'local',
          profileId: 'mineru',
          displayName: 'Mineru Builder',
          serverLabel: 'local',
          health: NavivoxProfileHealth.online,
          latestPreview: 'Goncho memory active',
        ),
      ], selectedKey: 'local::mineru')
      ..emitConfigSchema(const {
        'fields': [
          {'name': 'provider', 'type': 'string', 'required': true},
        ],
      })
      ..emitConfigValues(const {'provider': 'openai'});

    await tester.pumpWidget(
      TestNavivoxMaterialApp(channel: channel, home: const ConfigScreen()),
    );

    expect(find.text('Profile config scope'), findsOneWidget);
    expect(find.text('Server: Local Gormes'), findsOneWidget);
    expect(find.text('Profile: Mineru Builder'), findsOneWidget);
    expect(find.text('Profile ID: mineru'), findsOneWidget);
  });

  testWidgets('renders each schema field with its current value', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..emitConfigSchema(const {
        'fields': [
          {'name': 'provider', 'type': 'string', 'required': true},
          {'name': 'temperature', 'type': 'number', 'required': false},
        ],
      })
      ..emitConfigValues(const {'provider': 'anthropic', 'temperature': 0.4});

    await tester.pumpWidget(
      TestNavivoxMaterialApp(channel: channel, home: const ConfigScreen()),
    );

    expect(find.text('provider'), findsOneWidget);
    expect(find.text('anthropic'), findsOneWidget);
    expect(find.text('temperature'), findsOneWidget);
    expect(find.text('0.4'), findsOneWidget);
  });

  testWidgets('renders server-provided config sections', (tester) async {
    final channel = TestNavivoxChannel()
      ..emitConfigSchema(const {
        'sections': [
          {
            'id': 'providers',
            'label': 'Provider and Models',
            'description': 'Model and provider defaults.',
            'fields': ['providers.default', 'model.temperature'],
          },
          {
            'id': 'gateway',
            'label': 'Navivox Gateway',
            'description': 'Gateway exposure and auth.',
            'fields': ['navivox.exposure_mode'],
          },
        ],
        'fields': [
          {'path': 'providers.default', 'label': 'Default provider'},
          {
            'path': 'model.temperature',
            'label': 'Temperature',
            'type': 'number',
          },
          {'path': 'navivox.exposure_mode', 'label': 'Exposure mode'},
          {'path': 'tools.allow_shell', 'label': 'Allow shell tools'},
        ],
      })
      ..emitConfigValues(const {
        'providers.default': 'openai',
        'model.temperature': 0.4,
        'navivox.exposure_mode': 'local',
        'tools.allow_shell': false,
      });

    await tester.pumpWidget(
      TestNavivoxMaterialApp(channel: channel, home: const ConfigScreen()),
    );

    expect(find.text('Provider and Models'), findsOneWidget);
    expect(find.text('Model and provider defaults.'), findsOneWidget);
    expect(find.text('Default provider'), findsOneWidget);
    expect(find.text('Temperature'), findsOneWidget);
    expect(find.text('Navivox Gateway'), findsOneWidget);
    expect(find.text('Gateway exposure and auth.'), findsOneWidget);
    expect(find.text('Exposure mode'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Other config'),
      300,
      scrollable: find.byType(Scrollable),
    );

    expect(find.text('Other config'), findsOneWidget);
    expect(find.text('Allow shell tools'), findsOneWidget);
  });

  testWidgets(
    'section-scoped config screen renders only the requested section',
    (tester) async {
      final channel = TestNavivoxChannel()
        ..emitConfigSchema(const {
          'sections': [
            {
              'id': 'providers',
              'label': 'Provider and Models',
              'fields': ['providers.default'],
            },
            {
              'id': 'gateway',
              'label': 'Navivox Gateway',
              'fields': ['navivox.exposure_mode'],
            },
          ],
          'fields': [
            {'path': 'providers.default', 'label': 'Default provider'},
            {'path': 'navivox.exposure_mode', 'label': 'Exposure mode'},
          ],
        })
        ..emitConfigValues(const {
          'providers.default': 'openai',
          'navivox.exposure_mode': 'local',
        });

      await tester.pumpWidget(
        TestNavivoxMaterialApp(
          channel: channel,
          home: const ConfigScreen(sectionId: 'providers'),
        ),
      );

      expect(find.text('Provider and Models'), findsOneWidget);
      expect(find.text('Default provider'), findsOneWidget);
      expect(find.text('Navivox Gateway'), findsNothing);
      expect(find.text('Exposure mode'), findsNothing);
    },
  );

  testWidgets('unknown config section shows a safe missing-section state', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..emitConfigSchema(const {
        'sections': [
          {
            'id': 'providers',
            'label': 'Provider and Models',
            'fields': ['providers.default'],
          },
        ],
        'fields': [
          {'path': 'providers.default', 'label': 'Default provider'},
        ],
      })
      ..emitConfigValues(const {'providers.default': 'openai'});

    await tester.pumpWidget(
      TestNavivoxMaterialApp(
        channel: channel,
        home: const ConfigScreen(sectionId: 'missing'),
      ),
    );

    expect(find.text('Config section not found: missing'), findsOneWidget);
    expect(find.text('Provider and Models'), findsNothing);
    expect(find.text('Default provider'), findsNothing);
  });

  testWidgets(
    'secret fields render redacted and save through sendConfigSecretSet',
    (tester) async {
      final channel = TestNavivoxChannel()
        ..emitConfigSchema(const {
          'fields': [
            {
              'path': 'providers.openai.api_key',
              'label': 'OpenAI API key',
              'type': 'secret',
              'secret': true,
            },
          ],
        })
        ..emitConfigValues(const {
          'providers.openai.api_key': {
            'secret_status': 'configured',
            'value': 'nvbx_secret_should_not_render',
          },
        });

      await tester.pumpWidget(
        TestNavivoxMaterialApp(channel: channel, home: const ConfigScreen()),
      );

      expect(find.text('OpenAI API key'), findsOneWidget);
      expect(find.text('Secret configured'), findsOneWidget);
      expect(
        find.textContaining('nvbx_secret_should_not_render'),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const ValueKey('config-edit-providers.openai.api_key')),
      );
      await tester.pump();

      await tester.enterText(
        find.byKey(const ValueKey('config-input-providers.openai.api_key')),
        'new-secret',
      );
      await tester.tap(
        find.byKey(const ValueKey('config-save-providers.openai.api_key')),
      );
      await tester.pump();

      expect(channel.configSetCalls, isEmpty);
      expect(channel.configSecretSetCalls, isEmpty);
      expect(find.text('Pending config changes'), findsOneWidget);
      expect(
        find.text(
          'OpenAI API key: Secret configured -> Secret will be updated',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('new-secret'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('config-apply-pending')));
      await tester.pump();

      expect(channel.configSetCalls, isEmpty);
      expect(channel.configSecretSetCalls, [
        (name: 'providers.openai.api_key', secret: 'new-secret'),
      ]);
    },
  );

  testWidgets('validation errors render at fields and disable apply', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..emitConfigSchema(const {
        'fields': [
          {
            'path': 'navivox.exposure_mode',
            'label': 'Exposure mode',
            'type': 'string',
          },
        ],
      })
      ..emitConfigValues(const {'navivox.exposure_mode': 'local'})
      ..emitConfigDiff(const {
        'validation_errors': [
          {
            'path': 'navivox.exposure_mode',
            'message': 'Public exposure requires explicit server confirmation.',
          },
        ],
      });

    await tester.pumpWidget(
      TestNavivoxMaterialApp(channel: channel, home: const ConfigScreen()),
    );

    await tester.tap(
      find.byKey(const ValueKey('config-edit-navivox.exposure_mode')),
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('config-input-navivox.exposure_mode')),
      'public',
    );
    await tester.tap(
      find.byKey(const ValueKey('config-save-navivox.exposure_mode')),
    );
    await tester.pump();

    expect(
      find.text('Public exposure requires explicit server confirmation.'),
      findsWidgets,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Apply pending changes'),
          )
          .onPressed,
      isNull,
    );
    expect(channel.configSetCalls, isEmpty);
  });

  testWidgets(
    'high-risk pending config changes require confirmation before apply',
    (tester) async {
      final channel = TestNavivoxChannel()
        ..emitConfigSchema(const {
          'fields': [
            {
              'path': 'navivox.exposure_mode',
              'label': 'Exposure mode',
              'type': 'string',
              'risk_level': 'high',
              'restart_required': true,
            },
          ],
        })
        ..emitConfigValues(const {'navivox.exposure_mode': 'local'});

      await tester.pumpWidget(
        TestNavivoxMaterialApp(channel: channel, home: const ConfigScreen()),
      );

      await tester.tap(
        find.byKey(const ValueKey('config-edit-navivox.exposure_mode')),
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('config-input-navivox.exposure_mode')),
        'public',
      );
      await tester.tap(
        find.byKey(const ValueKey('config-save-navivox.exposure_mode')),
      );
      await tester.pump();

      expect(find.text('Pending config changes'), findsOneWidget);
      expect(find.text('Exposure mode: local -> public'), findsOneWidget);
      expect(find.text('Restart required'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('config-apply-pending')));
      await tester.pumpAndSettle();

      expect(find.text('Confirm high-risk config changes'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Exposure mode: local -> public'),
        ),
        findsOneWidget,
      );
      expect(channel.configSetCalls, isEmpty);

      await tester.tap(find.text('Confirm apply'));
      await tester.pumpAndSettle();

      expect(channel.configSetCalls, [
        (field: 'navivox.exposure_mode', value: 'public'),
      ]);
    },
  );

  testWidgets('editing a number field stages a draft before apply', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..emitConfigSchema(const {
        'fields': [
          {'name': 'temperature', 'type': 'number', 'required': false},
        ],
      })
      ..emitConfigValues(const {'temperature': 0.4});

    await tester.pumpWidget(
      TestNavivoxMaterialApp(channel: channel, home: const ConfigScreen()),
    );

    await tester.tap(find.byKey(const ValueKey('config-edit-temperature')));
    await tester.pump();

    await tester.enterText(
      find.byKey(const ValueKey('config-input-temperature')),
      '0.7',
    );
    await tester.tap(find.byKey(const ValueKey('config-save-temperature')));
    await tester.pump();

    expect(channel.configSetCalls, isEmpty);
    expect(find.text('Pending config changes'), findsOneWidget);
    expect(find.text('temperature: 0.4 -> 0.7'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('config-apply-pending')));
    await tester.pump();

    expect(channel.configSetCalls, [(field: 'temperature', value: 0.7)]);
  });

  testWidgets(
    'safe config admin validates diffs and applies through backend with reload evidence',
    (tester) async {
      final channel = TestNavivoxChannel()
        ..emitConfigSchema(const {
          'fields': [
            {
              'key': 'navivox.port',
              'title': 'Port',
              'type': 'int',
              'reload': 'restart_or_reload',
            },
            {
              'key': 'navivox.token',
              'title': 'Pairing/static token',
              'type': 'secret',
              'secret': true,
              'actions': ['set', 'rotate', 'delete', 'test'],
              'reload': 'restart_or_reload',
            },
          ],
        })
        ..emitConfigValues(const {
          'navivox.port': 8765,
          'navivox.token': {
            'secret_status': 'set',
            'source': 'env:GORMES_NAVIVOX_TOKEN',
            'value': 'nvbx_secret_should_not_render',
          },
        })
        ..seedConfigAdminResponses(
          validate: const NavivoxConfigAdminResponse(
            action: 'config.validate',
            valid: true,
            changes: [
              NavivoxConfigAdminDiff(
                key: 'navivox.port',
                type: 'int',
                before: 8765,
                after: 8766,
              ),
            ],
          ),
          diff: const NavivoxConfigAdminResponse(
            action: 'config.diff',
            valid: true,
            changes: [
              NavivoxConfigAdminDiff(
                key: 'navivox.port',
                type: 'int',
                before: 8765,
                after: 8766,
              ),
            ],
          ),
          apply: const NavivoxConfigAdminResponse(
            action: 'config.apply',
            valid: true,
            applied: true,
            reloadApplied: true,
            pendingRestart: false,
            changes: [
              NavivoxConfigAdminDiff(
                key: 'navivox.port',
                type: 'int',
                before: 8765,
                after: 8766,
              ),
            ],
          ),
        );

      await tester.pumpWidget(
        TestNavivoxMaterialApp(channel: channel, home: const ConfigScreen()),
      );

      expect(find.text('Port'), findsOneWidget);
      expect(find.text('8765'), findsOneWidget);
      expect(find.text('Pairing/static token'), findsOneWidget);
      expect(
        find.text('Secret configured (env:GORMES_NAVIVOX_TOKEN)'),
        findsOneWidget,
      );
      expect(find.text('Actions: set, rotate, delete, test'), findsOneWidget);
      expect(
        find.textContaining('nvbx_secret_should_not_render'),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('config-edit-navivox.port')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('config-input-navivox.port')),
        '8766',
      );
      await tester.tap(find.byKey(const ValueKey('config-save-navivox.port')));
      await tester.pump();
      await tester.drag(find.byType(Scrollable), const Offset(0, -500));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('config-apply-pending')));
      await tester.pumpAndSettle();

      expect(channel.configSetCalls, isEmpty);
      expect(channel.configSecretSetCalls, isEmpty);
      expect(
        channel.configAdminValidateCalls.single.single.key,
        'navivox.port',
      );
      expect(
        channel.configAdminDiffCalls.single.single.toJson()['value'],
        '8766',
      );
      expect(
        channel.configAdminApplyCalls.single.single.toJson()['value'],
        '8766',
      );
      expect(find.text('Config reload applied by Gormes.'), findsOneWidget);
      expect(find.text('navivox.port: 8765 -> 8766'), findsOneWidget);
    },
  );

  testWidgets('safe config admin validation errors block apply', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..emitConfigSchema(const {
        'fields': [
          {
            'key': 'navivox.exposure_mode',
            'title': 'Exposure mode',
            'type': 'enum',
            'allowed': ['local', 'public'],
          },
        ],
      })
      ..emitConfigValues(const {'navivox.exposure_mode': 'local'})
      ..seedConfigAdminResponses(
        validate: const NavivoxConfigAdminResponse(
          action: 'config.validate',
          valid: false,
          errors: [
            NavivoxConfigAdminFieldError(
              key: 'navivox.exposure_mode',
              code: 'invalid_runtime',
              message: 'Public exposure requires explicit server confirmation.',
            ),
          ],
        ),
        diff: const NavivoxConfigAdminResponse(
          action: 'config.diff',
          valid: true,
        ),
        apply: const NavivoxConfigAdminResponse(
          action: 'config.apply',
          valid: true,
          applied: true,
        ),
      );

    await tester.pumpWidget(
      TestNavivoxMaterialApp(channel: channel, home: const ConfigScreen()),
    );

    await tester.tap(
      find.byKey(const ValueKey('config-edit-navivox.exposure_mode')),
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('config-input-navivox.exposure_mode')),
      'public',
    );
    await tester.tap(
      find.byKey(const ValueKey('config-save-navivox.exposure_mode')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('config-apply-pending')));
    await tester.pumpAndSettle();

    expect(
      find.text('Public exposure requires explicit server confirmation.'),
      findsWidgets,
    );
    expect(channel.configAdminValidateCalls, hasLength(1));
    expect(channel.configAdminDiffCalls, isEmpty);
    expect(channel.configAdminApplyCalls, isEmpty);
    expect(channel.configSetCalls, isEmpty);
  });
}
