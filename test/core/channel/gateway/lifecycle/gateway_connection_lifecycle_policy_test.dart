import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/gateway/lifecycle/gateway_connection_lifecycle_policy.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/gateway/navivox_gateway_protocol.dart';

void main() {
  test('closed capability state keeps a safe fallback profile contact', () {
    final state = navivoxClosedCapabilityGatewayState(
      state: const NavivoxChannelState(),
      config: NavivoxGatewayConfig(
        baseUri: Uri.parse('https://gw.example:8765'),
      ),
      status: 'Capabilities unavailable',
    );

    expect(state.servers, hasLength(1));
    expect(state.activeServer?.status, contains('Capabilities unavailable'));
    expect(state.activeServer?.status, contains('gw.example:8765'));
    expect(state.profileContacts, hasLength(1));
    expect(state.selectedProfileContactKey, state.profileContacts.single.key);
    expect(state.runRecordInspectionAvailable, isFalse);
    expect(state.configSchema, isEmpty);
    expect(state.configValues, isEmpty);
    expect(state.configDiff, isEmpty);
  });

  test('connected state applies contacts and advertised feature state', () {
    const contact = NavivoxProfileContact(
      serverId: 'gateway-1',
      profileId: 'default',
      displayName: 'Default profile',
      serverLabel: 'Gormes Gateway',
      health: NavivoxProfileHealth.online,
      latestPreview: 'Ready',
    );

    final state = navivoxConnectedGatewayState(
      state: const NavivoxChannelState(),
      config: NavivoxGatewayConfig(baseUri: Uri.parse('http://127.0.0.1:8765')),
      capabilities: _capabilities(
        runRecordsEndpoint: '/v1/navivox/run-records',
      ),
      contacts: const [contact],
      profileRouting: const NavivoxProfileRoutingReport(),
      configSchema: const {'enabled': true},
      configValues: const {'enabled': false},
    );

    expect(state.activeServer?.id, 'gateway-1');
    expect(state.profileContacts.single, contact);
    expect(state.selectedProfileContactKey, contact.key);
    expect(state.runRecordInspectionAvailable, isTrue);
    expect(state.configSchema, {'enabled': true});
    expect(state.configValues, {'enabled': false});
    expect(state.configDiff, isEmpty);
  });

  test('failed saved-session reconnect clears stale gateway routing state', () {
    const contact = NavivoxProfileContact(
      serverId: 'gateway-1',
      profileId: 'default',
      displayName: 'Default profile',
      serverLabel: 'Gormes Gateway',
      health: NavivoxProfileHealth.online,
      latestPreview: 'Ready',
    );
    final stale = const NavivoxChannelState().copyWith(
      servers: const [
        NavivoxServer(
          id: 'gateway-1',
          name: 'Gormes Gateway',
          status: 'online',
        ),
      ],
      activeServerId: 'gateway-1',
      profileContacts: const [contact],
      selectedProfileContactKey: contact.key,
      runRecordInspectionAvailable: true,
      configSchema: const {'secret': true},
      configValues: const {'secret': 'redacted'},
      configDiff: const {'secret': 'changed'},
    );

    final state = navivoxFailedSavedSessionReconnectState(state: stale);

    expect(state.servers, isEmpty);
    expect(state.activeServerId, isNull);
    expect(state.profileContacts, isEmpty);
    expect(state.selectedProfileContactKey, isNull);
    expect(state.runRecordInspectionAvailable, isFalse);
    expect(state.configSchema, isEmpty);
    expect(state.configValues, isEmpty);
    expect(state.configDiff, isEmpty);
  });
}

NavivoxCapabilityDocument _capabilities({String runRecordsEndpoint = ''}) {
  return NavivoxCapabilityDocument(
    object: 'gormes.navivox.capabilities',
    protocolVersion: navivoxWebSocketProtocol,
    capabilities: const ['profile_contacts', 'stream_turns'],
    auth: const NavivoxCapabilityAuth(
      mode: 'bearer',
      headers: ['authorization'],
      webSocketProtocols: ['bearer'],
    ),
    healthAliases: const [],
    endpoints: const [
      NavivoxCapabilityEndpoint(
        method: 'GET',
        path: '/v1/navivox/capabilities',
        auth: 'bearer',
        stability: 'stable',
        description: 'Capabilities',
      ),
    ],
    profileManagement: const NavivoxProfileManagementCapability(
      contactsEndpoint: '/v1/navivox/profile-contacts',
      routingEndpoint: '',
      createFromSeedEndpoint: '',
      dashboardApiExposed: false,
      supportedActions: [],
      unsupportedActions: [],
      profileContractParts: [],
    ),
    attachments: const NavivoxAttachmentCapability(
      maxRequestBytes: 0,
      opaqueUploadIds: false,
      rawLocalPathsAccepted: false,
      workspaceFileAttach: false,
      mimeAllowlist: [],
      retention: '',
    ),
    voice: NavivoxVoiceProtocolCapability(
      deviceTranscribedTextTurns: false,
      rawAudioUpload: false,
      voiceProfilesEndpoint: '',
      runRecordsEndpoint: runRecordsEndpoint,
      sttProviders: const [],
      ttsProviders: const [],
    ),
    streams: const NavivoxStreamCapability(
      canonicalEndpoint: '/v1/navivox/stream',
      transport: 'websocket',
      eventKinds: [],
      openAiRunsBridge: false,
    ),
    durableReconnect: const NavivoxDurableReconnectCapability(
      supported: false,
      issueEndpoint: '',
      authMethods: [],
      platforms: [],
      effectiveSecurity: '',
      blockedReason: '',
    ),
  );
}
