import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../core/hermes/models/hermes_health.dart';
import '../../../l10n/app_localizations.dart';
import '../../hermes_chat/gateways/hermes_gateway_directory.dart';
import '../../hermes_chat/providers/hermes_channel_provider.dart';

/// Gateway-selected, bounded, read-only health. Lifecycle, logs, and messaging
/// platform administration are deliberately absent until dedicated scoped
/// contracts are advertised.
class GatewayScreen extends ConsumerStatefulWidget {
  const GatewayScreen({super.key});

  @override
  ConsumerState<GatewayScreen> createState() => _GatewayScreenState();
}

class _GatewayScreenState extends ConsumerState<GatewayScreen> {
  String? _switchingGatewayId;
  String? _actionError;
  bool _refreshing = false;
  bool _refreshFailed = false;

  @override
  Widget build(BuildContext context) {
    final channel = ref.watch(hermesChannelProvider);
    final directory = ref.watch(hermesGatewayDirectoryProvider);
    final strings = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([channel, directory]),
      builder: (context, _) {
        final canRefresh = _detailedHealthAdvertised(channel.state);
        return Scaffold(
          appBar: AppBar(
            title: Text(strings.gatewayStatusTitle),
            actions: [
              if (canRefresh)
                IconButton(
                  key: const ValueKey('gateway-refresh-button'),
                  tooltip: strings.gatewayStatusRefreshTooltip,
                  onPressed: _refreshing
                      ? null
                      : () => unawaited(_refresh(channel)),
                  icon: _refreshing
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                ),
            ],
          ),
          body: Column(
            children: [
              if (directory.gateways.isNotEmpty)
                _buildGatewayPicker(directory, strings),
              if (_actionError != null)
                MaterialBanner(
                  content: Text(_actionError!),
                  actions: [
                    TextButton(
                      onPressed: () => setState(() => _actionError = null),
                      child: Text(strings.doneAction),
                    ),
                  ],
                ),
              Expanded(
                child: _GatewayBody(
                  state: channel.state,
                  strings: strings,
                  refreshFailed: _refreshFailed,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGatewayPicker(
    HermesGatewayDirectory directory,
    AppLocalizations strings,
  ) {
    final selectedId = directory.activeContactId?.gatewayId;
    final selected =
        directory.gateways.any((gateway) => gateway.id == selectedId)
        ? selectedId
        : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            key: const ValueKey('gateway-status-picker'),
            initialValue: selected,
            decoration: InputDecoration(
              labelText: strings.gatewayLabel,
              border: const OutlineInputBorder(),
            ),
            hint: Text(strings.selectGatewayHint),
            items: [
              for (final gateway in directory.gateways)
                DropdownMenuItem(value: gateway.id, child: Text(gateway.label)),
            ],
            onChanged: _switchingGatewayId == null
                ? (gatewayId) {
                    if (gatewayId != null && gatewayId != selected) {
                      unawaited(_selectGateway(directory, gatewayId, strings));
                    }
                  }
                : null,
          ),
          const SizedBox(height: 6),
          Text(strings.gatewayStatusHelp),
        ],
      ),
    );
  }

  Future<void> _selectGateway(
    HermesGatewayDirectory directory,
    String gatewayId,
    AppLocalizations strings,
  ) async {
    setState(() {
      _switchingGatewayId = gatewayId;
      _actionError = null;
      _refreshFailed = false;
    });
    try {
      await directory.activateGateway(gatewayId);
    } catch (_) {
      if (mounted) setState(() => _actionError = strings.gatewayConnectFailed);
    } finally {
      if (mounted) setState(() => _switchingGatewayId = null);
    }
  }

  Future<void> _refresh(HermesChannel channel) async {
    setState(() {
      _refreshing = true;
      _refreshFailed = false;
    });
    try {
      await channel.loadDetailedHealth();
    } catch (_) {
      if (mounted) setState(() => _refreshFailed = true);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }
}

class _GatewayBody extends StatelessWidget {
  const _GatewayBody({
    required this.state,
    required this.strings,
    required this.refreshFailed,
  });

  final HermesChannelState state;
  final AppLocalizations strings;
  final bool refreshFailed;

  @override
  Widget build(BuildContext context) {
    if (state.status == HermesConnectionStatus.connecting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status != HermesConnectionStatus.connected) {
      return _CenteredMessage(
        state.status == HermesConnectionStatus.error
            ? strings.gatewayStatusConnectionErrorBody
            : strings.gatewayStatusConnectionRequiredBody,
      );
    }
    if (!_detailedHealthAdvertised(state)) {
      return _CenteredMessage(strings.gatewayStatusUnavailableBody);
    }
    if (refreshFailed ||
        state.optionalResourceErrors.containsKey(
          HermesOptionalResource.detailedHealth,
        )) {
      return _CenteredMessage(strings.gatewayStatusLoadFailedBody);
    }
    final health = state.detailedHealth;
    if (health == null) {
      return _CenteredMessage(strings.gatewayStatusLoadFailedBody);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        Text(
          strings.gatewayStatusTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(strings.gatewayStatusSubtitle),
        const SizedBox(height: 16),
        Card(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.visibility_outlined),
                const SizedBox(width: 12),
                Expanded(child: Text(strings.gatewayStatusReadOnlyNote)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _HealthCard(health: health, strings: strings),
      ],
    );
  }
}

class _HealthCard extends StatelessWidget {
  const _HealthCard({required this.health, required this.strings});

  final HermesHealthStatus health;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  health.isOk
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_outlined,
                  color: health.isOk ? colors.primary : colors.error,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    health.isOk
                        ? strings.gatewayHealthy
                        : strings.gatewayNeedsAttention,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _StatusRow(
              label: strings.gatewayPlatformLabel,
              value: _safePreview(health.platform, 80),
            ),
            if (health.version?.trim().isNotEmpty ?? false) ...[
              const SizedBox(height: 10),
              _StatusRow(
                label: strings.gatewayVersionLabel,
                value: _safePreview(health.version!, 80),
              ),
            ],
            if (health.gatewayState?.trim().isNotEmpty ?? false) ...[
              const SizedBox(height: 10),
              _StatusRow(
                label: strings.gatewayRuntimeStateLabel,
                value: _safePreview(health.gatewayState!, 80),
              ),
            ],
            const SizedBox(height: 10),
            _StatusRow(
              label: strings.gatewayActiveAgentsLabel,
              value: health.activeAgents.toString(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 112,
        child: Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(child: Text(value)),
    ],
  );
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}

bool _detailedHealthAdvertised(HermesChannelState state) {
  final capabilities = state.capabilities;
  return state.status == HermesConnectionStatus.connected &&
      capabilities?.supportsSchema == true &&
      capabilities!.advertisesEndpoint(
        'health_detailed',
        'GET',
        '/health/detailed',
      );
}

String _safePreview(String value, int maxLength) {
  final normalized = value
      .replaceAll(RegExp(r'[\u0000-\u001f\u007f]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (normalized.length <= maxLength) return normalized;
  return '${normalized.substring(0, maxLength - 1)}…';
}
