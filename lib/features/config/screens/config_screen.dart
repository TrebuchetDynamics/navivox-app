import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/channel/navivox_channel.dart';
import '../../../core/channel/navivox_channel_provider.dart';
import '../../../core/gateway/navivox_gateway_protocol.dart';
import '../../../router/app_routes.dart';
import '../../../shared/presentation/profile_contact_scope_presentation.dart';
import '../../../shared/widgets/gormes_legacy_notice.dart';
import '../../profiles/widgets/profile_voice_profile_card.dart';
import '../actions/config_admin_apply_coordinator.dart';
import '../apply/config_apply_dispatcher.dart';
import '../apply/config_apply_flow_model.dart';
import '../apply/config_apply_presentation.dart';
import '../form/config_draft_session.dart';
import '../form/config_field_presentation.dart';
import '../presentation/config_screen_presentation.dart';
import '../presentation/config_section_presentation.dart';

class ConfigScreen extends ConsumerStatefulWidget {
  const ConfigScreen({this.sectionId, super.key});

  final String? sectionId;

  @override
  ConsumerState<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends ConsumerState<ConfigScreen> {
  NavivoxChannel? _subscribed;
  final ConfigApplyDispatcher _applyDispatcher = const ConfigApplyDispatcher();
  final ConfigAdminApplyCoordinator _configAdminApplyCoordinator =
      const ConfigAdminApplyCoordinator();
  ConfigDraftSession _draftSession = ConfigDraftSession();
  final TextEditingController _controller = TextEditingController();
  NavivoxConfigAdminResponse? _lastConfigAdminApply;
  String? _configAdminError;
  bool _refreshingConfigAdmin = false;

  void _onChannelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _subscribed?.removeListener(_onChannelChanged);
    _controller.dispose();
    super.dispose();
  }

  void _stageDraft(ConfigFieldPresentation field) {
    setState(() {
      _draftSession = _draftSession.stageEdit(field, _controller.text);
    });
  }

  Future<void> _applyPendingChanges(ConfigApplyFlowModel flow) async {
    if (!flow.canApply) return;
    final channel = ref.read(navivoxChannelProvider);
    if (channel.configAdminAvailable) {
      await _applyConfigAdminChanges(flow, channel);
      return;
    }

    final presentation = ConfigApplyPresentation.fromFlow(flow);
    if (presentation.requiresConfirmation) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) =>
            _ConfigConfirmationDialog(presentation: presentation),
      );
      if (!mounted || confirmed != true) return;
    }

    final result = _applyDispatcher.dispatch(flow: flow, channel: channel);
    if (!result.wasDispatched) return;
    setState(() {
      _draftSession = _draftSession.clearApplied(flow);
    });
  }

  Future<void> _applyConfigAdminChanges(
    ConfigApplyFlowModel flow,
    NavivoxChannel channel,
  ) async {
    final changes = _configAdminApplyCoordinator.changesFromFlow(flow);
    if (changes.isEmpty) return;
    setState(() {
      _configAdminError = null;
      _lastConfigAdminApply = null;
    });
    try {
      final validation = await channel.validateConfigAdmin(changes);
      if (!mounted) return;
      if (!_applyConfigAdminEffect(
        _configAdminApplyCoordinator.afterValidation(validation),
        flow,
      )) {
        return;
      }
      final diff = await channel.diffConfigAdmin(changes);
      if (!mounted) return;
      if (!_applyConfigAdminEffect(
        _configAdminApplyCoordinator.afterDiff(diff),
        flow,
      )) {
        return;
      }
      final presentation = ConfigApplyPresentation.fromFlow(flow);
      if (presentation.requiresConfirmation) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => _ConfigConfirmationDialog(
            presentation: presentation,
            backendDiff: diff,
          ),
        );
        if (!mounted || confirmed != true) return;
      }
      final applied = await channel.applyConfigAdmin(changes);
      if (!mounted) return;
      _applyConfigAdminEffect(
        _configAdminApplyCoordinator.afterApply(applied),
        flow,
      );
    } catch (_) {
      if (!mounted) return;
      _applyConfigAdminEffect(
        _configAdminApplyCoordinator.requestFailed(),
        flow,
      );
    }
  }

  bool _applyConfigAdminEffect(
    ConfigAdminApplyEffect effect,
    ConfigApplyFlowModel flow,
  ) {
    switch (effect) {
      case ContinueConfigAdminApplyEffect():
        return true;
      case ShowConfigAdminApplyErrorEffect(:final message):
        setState(() {
          _configAdminError = message;
        });
        return false;
      case MarkConfigAdminAppliedEffect(:final response):
        setState(() {
          _lastConfigAdminApply = response;
          _draftSession = _draftSession.clearApplied(flow);
        });
        return false;
    }
  }

  Future<void> _refreshConfigAdmin(NavivoxChannel channel) async {
    if (_refreshingConfigAdmin) return;
    setState(() {
      _refreshingConfigAdmin = true;
      _configAdminError = null;
    });
    try {
      await channel.refreshConfigAdmin();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _configAdminError = 'Config admin could not be refreshed.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _refreshingConfigAdmin = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final channel = ref.watch(navivoxChannelProvider);
    if (!identical(_subscribed, channel)) {
      _subscribed?.removeListener(_onChannelChanged);
      channel.addListener(_onChannelChanged);
      _subscribed = channel;
    }

    final screen = ConfigScreenPresentation.fromState(
      state: channel.state,
      sectionId: widget.sectionId,
      draftSession: _draftSession,
      configAdminAvailable: channel.configAdminAvailable,
      configAdminSupported: channel.configAdminSupported,
      configAdminLoadFailed: channel.configAdminLoadFailed,
      configAdminChecking: _refreshingConfigAdmin,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Config')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _ConfigReadinessCard(
              scope: screen.scope,
              readiness: screen.configReadiness,
              onRefresh: () => _refreshConfigAdmin(channel),
              onOpenGateway: () =>
                  GoRouter.maybeOf(context)?.go(AppRoutes.servers),
            ),
            if (screen.isMissingSection)
              _MissingConfigSectionCard(message: screen.missingSectionMessage)
            else if (!screen.isEmpty)
              for (final section in screen.sections)
                _ConfigSectionCard(
                  section: section,
                  controller: _controller,
                  onEdit: (field) {
                    _controller.text = _draftSession.editInitialValueFor(field);
                    setState(() {
                      _draftSession = _draftSession.beginEditing(field);
                    });
                  },
                  onCancel: () => setState(() {
                    _draftSession = _draftSession.cancelEditing();
                  }),
                  onSave: _stageDraft,
                ),
            if (channel.state.activeProfileContact != null)
              ProfileVoiceProfileCard(channel: channel),
            if (screen.showPendingChanges)
              _ConfigPendingChangesCard(
                presentation: screen.applyPresentation,
                onApply: () => _applyPendingChanges(screen.applyFlow),
              ),
            if (_configAdminError != null)
              _ConfigAdminStatusCard(
                message: _configAdminError!,
                isError: true,
              ),
            if (_lastConfigAdminApply != null)
              _ConfigAdminApplyResultCard(result: _lastConfigAdminApply!),
            const GormesLegacyNotice(),
          ],
        ),
      ),
    );
  }
}

class _ConfigReadinessCard extends StatelessWidget {
  const _ConfigReadinessCard({
    required this.scope,
    required this.readiness,
    required this.onRefresh,
    required this.onOpenGateway,
  });

  final ProfileContactScopePresentation scope;
  final ConfigReadinessPresentation readiness;
  final VoidCallback onRefresh;
  final VoidCallback onOpenGateway;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final actions = Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: readiness.canRefresh ? onRefresh : null,
                  icon: const Icon(Icons.refresh),
                  label: Text(readiness.refreshLabel),
                ),
                TextButton.icon(
                  onPressed: onOpenGateway,
                  icon: const Icon(Icons.dns_outlined),
                  label: Text(readiness.openGatewayLabel),
                ),
              ],
            );
            if (readiness.status == ConfigReadinessStatus.ready) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(readiness.statusLabel),
                  const SizedBox(height: 6),
                  Text(
                    'Profile config scope',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text('Server: ${scope.serverLabel}')),
                      Chip(label: Text('Profile: ${scope.profileLabel}')),
                      if (scope.profileId != null)
                        Chip(label: Text('Profile ID: ${scope.profileId}')),
                    ],
                  ),
                ],
              );
            }
            final statusColor = readiness.canRefresh
                ? theme.colorScheme.primary
                : theme.colorScheme.error;
            final heading = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    readiness.canRefresh
                        ? Icons.settings_suggest_outlined
                        : Icons.warning_amber_rounded,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(readiness.title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        readiness.statusLabel,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (constraints.maxWidth >= 560)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: heading),
                      actions,
                    ],
                  )
                else ...[
                  heading,
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerRight, child: actions),
                ],
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.24),
                    ),
                  ),
                  child: Text(readiness.message),
                ),
                const SizedBox(height: 12),
                Text('Profile config scope', style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text('Server: ${scope.serverLabel}')),
                    Chip(label: Text('Profile: ${scope.profileLabel}')),
                    if (scope.profileId != null)
                      Chip(label: Text('Profile ID: ${scope.profileId}')),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MissingConfigSectionCard extends StatelessWidget {
  const _MissingConfigSectionCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(child: Text(message)),
    );
  }
}

class _ConfigSectionCard extends StatelessWidget {
  const _ConfigSectionCard({
    required this.section,
    required this.controller,
    required this.onEdit,
    required this.onCancel,
    required this.onSave,
  });

  final ConfigSectionPresentation section;
  final TextEditingController controller;
  final ValueChanged<ConfigFieldPresentation> onEdit;
  final VoidCallback onCancel;
  final ValueChanged<ConfigFieldPresentation> onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(section.label, style: Theme.of(context).textTheme.titleMedium),
            if (section.hasDescription) ...[
              const SizedBox(height: 4),
              Text(section.description!),
            ],
            const SizedBox(height: 8),
            for (final field in section.fields)
              _ConfigRow(
                field: field.field,
                isEditing: field.isEditing,
                controller: controller,
                onEdit: onEdit,
                onCancel: onCancel,
                onSave: onSave,
              ),
          ],
        ),
      ),
    );
  }
}

class _ConfigPendingChangesCard extends StatelessWidget {
  const _ConfigPendingChangesCard({
    required this.presentation,
    required this.onApply,
  });

  final ConfigApplyPresentation presentation;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              presentation.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final change in presentation.changes) ...[
              Text(change.summaryLabel),
              if (change.hasRestartLabel)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Chip(label: Text(change.restartLabel!)),
                ),
              for (final message in change.validationMessages)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                key: const ValueKey('config-apply-pending'),
                onPressed: presentation.canApply ? onApply : null,
                child: Text(presentation.applyButtonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfigAdminStatusCard extends StatelessWidget {
  const _ConfigAdminStatusCard({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: isError
              ? TextStyle(color: Theme.of(context).colorScheme.error)
              : null,
        ),
      ),
    );
  }
}

class _ConfigAdminApplyResultCard extends StatelessWidget {
  const _ConfigAdminApplyResultCard({required this.result});

  final NavivoxConfigAdminResponse result;

  @override
  Widget build(BuildContext context) {
    final status = result.reloadApplied
        ? 'Config reload applied by Gormes.'
        : result.pendingRestart
        ? 'Config changes pending restart.'
        : 'Config changes applied.';
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(status, style: Theme.of(context).textTheme.titleSmall),
            if (result.reloadError.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(result.reloadError),
            ],
            for (final change in result.changes)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(change.summaryLabel),
              ),
          ],
        ),
      ),
    );
  }
}

class _ConfigConfirmationDialog extends StatelessWidget {
  const _ConfigConfirmationDialog({
    required this.presentation,
    this.backendDiff,
  });

  final ConfigApplyPresentation presentation;
  final NavivoxConfigAdminResponse? backendDiff;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(presentation.confirmationTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(presentation.confirmationIntro),
          const SizedBox(height: 12),
          for (final summary in _confirmationSummaries()) ...[
            Text(summary),
            const SizedBox(height: 8),
          ],
          if (backendDiff == null)
            for (final change in presentation.changes) ...[
              if (change.hasRestartLabel)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Chip(label: Text(change.restartLabel!)),
                ),
              const SizedBox(height: 8),
            ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Confirm apply'),
        ),
      ],
    );
  }

  List<String> _confirmationSummaries() {
    final diff = backendDiff;
    if (diff != null && diff.changes.isNotEmpty) {
      return diff.changes.map((change) => change.summaryLabel).toList();
    }
    return presentation.changes
        .map((change) => change.summaryLabel)
        .toList(growable: false);
  }
}

class _ConfigRow extends StatelessWidget {
  const _ConfigRow({
    required this.field,
    required this.isEditing,
    required this.controller,
    required this.onEdit,
    required this.onCancel,
    required this.onSave,
  });

  final ConfigFieldPresentation field;
  final bool isEditing;
  final TextEditingController controller;
  final ValueChanged<ConfigFieldPresentation> onEdit;
  final VoidCallback onCancel;
  final ValueChanged<ConfigFieldPresentation> onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                if (isEditing)
                  TextField(
                    key: field.inputKey,
                    controller: controller,
                    obscureText: field.obscureText,
                    keyboardType: field.keyboardType,
                  )
                else
                  Text(field.displayValue),
                for (final helper in field.helperLines)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(helper),
                  ),
                for (final message in field.validationMessages)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      message,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isEditing) ...[
            IconButton(
              key: field.saveKey,
              icon: const Icon(Icons.check),
              onPressed: () => onSave(field),
            ),
            IconButton(icon: const Icon(Icons.close), onPressed: onCancel),
          ] else
            IconButton(
              key: field.editKey,
              icon: const Icon(Icons.edit),
              onPressed: () => onEdit(field),
            ),
        ],
      ),
    );
  }
}
