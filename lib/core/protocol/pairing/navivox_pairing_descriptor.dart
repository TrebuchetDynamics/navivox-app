import '../../gateway/client/navivox_gateway_config.dart';
import 'pairing_descriptor_endpoints.dart';
import 'pairing_descriptor_envelope.dart';
import 'pairing_descriptor_query_fields.dart';

class NavivoxPairingDescriptor {
  const NavivoxPairingDescriptor({
    required this.baseUri,
    required this.webSocketUri,
    required this.authMode,
    required this.exposureMode,
    required this.tokenRequired,
    this.token,
    this.serverId,
    this.profileId,
    this.workspaceId,
    this.providerId,
    this.setupEntryScreen,
    this.setupSections = const [],
    this.channelIds = const [],
  });

  factory NavivoxPairingDescriptor.parse(String value) {
    final envelope = PairingDescriptorEnvelope.parse(value);
    final fields = PairingDescriptorQueryFields(
      descriptor: value,
      queryParametersAll: envelope.queryParametersAll,
      rawQuery: envelope.rawQuery,
    );
    final tokenRequired = fields.boolean('token_required');
    final token = fields.optional('rest_token');
    if (tokenRequired && token == null) {
      throw FormatException('Pairing descriptor requires rest_token', value);
    }
    final endpoints = PairingDescriptorEndpoints.fromWireFields(
      webSocketUrl: fields.required('websocket_url'),
      explicitBaseUrl: fields.optional('base_url'),
      descriptor: value,
    );
    final authMode = fields.optional('auth_mode') ?? '';
    final exposureMode = fields.optional('exposure_mode') ?? '';
    if (_navivoxPairingRequiresStrongToken(exposureMode, authMode) &&
        !_navivoxExposedPairingTokenLooksStrong(token)) {
      throw FormatException(
        'Pairing descriptor token is too weak for exposed Navivox gateway',
        value,
      );
    }
    return NavivoxPairingDescriptor(
      baseUri: endpoints.baseUri,
      webSocketUri: endpoints.webSocketUri,
      authMode: authMode,
      exposureMode: exposureMode,
      tokenRequired: tokenRequired,
      token: token,
      serverId: fields.optional('server_id'),
      profileId: fields.optional('profile_id'),
      workspaceId: fields.optional('workspace_id'),
      providerId: fields.optional('provider_id'),
      setupEntryScreen: fields.optional('setup_entry_screen'),
      setupSections: fields.csv('setup_sections'),
      channelIds: fields.csv('channel_ids'),
    );
  }

  final Uri baseUri;
  final Uri webSocketUri;
  final String authMode;
  final String exposureMode;
  final bool tokenRequired;
  final String? token;
  final String? serverId;
  final String? profileId;
  final String? workspaceId;
  final String? providerId;
  final String? setupEntryScreen;
  final List<String> setupSections;
  final List<String> channelIds;

  NavivoxGatewayConfig toGatewayConfig() {
    return NavivoxGatewayConfig(
      baseUri: baseUri,
      token: token,
      webSocketUri: webSocketUri,
    );
  }
}

const _navivoxMinExposedTokenLength = 32;
const _navivoxMinExposedTokenDistinctChars = 16;

bool _navivoxExposedPairingTokenLooksStrong(String? token) {
  if (token == null || token.length < _navivoxMinExposedTokenLength) {
    return false;
  }
  return token.runes.toSet().length >= _navivoxMinExposedTokenDistinctChars;
}

bool _navivoxPairingRequiresStrongToken(String exposureMode, String authMode) {
  switch (exposureMode.trim().toLowerCase()) {
    case 'tailscale':
    case 'wireguard':
    case 'vpn':
    case 'public':
      break;
    default:
      return false;
  }
  switch (authMode.trim().toLowerCase()) {
    case 'pairing_token':
    case 'static_token':
    case 'token_and_tailscale_identity':
      return true;
    default:
      return false;
  }
}
