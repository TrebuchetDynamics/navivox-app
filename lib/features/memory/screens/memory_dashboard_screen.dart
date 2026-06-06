import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/channel/navivox_channel.dart';
import '../../../core/channel/navivox_channel_provider.dart';
import '../../../core/protocol/navivox_memory.dart';
import '../../../router/app_routes.dart';
import '../../../shared/presentation/profile_contact_scope_presentation.dart';
import '../actions/memory_dashboard_action_coordinator.dart';
import '../presentation/memory_dashboard_presentation.dart';

const _memoryPresentation = MemoryDashboardPresentation();
const _memoryActions = MemoryDashboardActionCoordinator();

final memoryOverviewProvider =
    FutureProvider.autoDispose<NavivoxMemoryOverview>((ref) {
      final channel = ref.watch(navivoxChannelProvider);
      final activeProfile = channel.state.activeProfileContact;
      final scope = _memoryActions.scopeFor(activeProfile);
      return channel.memoryOverview(
        serverId: scope.serverId,
        profileId: scope.profileId,
      );
    });

class MemoryDashboardScreen extends ConsumerWidget {
  const MemoryDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channel = ref.watch(navivoxChannelProvider);
    final state = channel.state;
    final activeProfile = state.activeProfileContact;
    final scope = ProfileContactScopePresentation(
      activeServer: state.activeServer,
      activeServerId: state.activeServerId,
      activeProfile: activeProfile,
    );
    final overview = ref.watch(memoryOverviewProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_memoryPresentation.title)),
      body: overview.when(
        loading: () => _MemoryReadinessOnlyBody(
          scope: scope,
          readiness: _memoryPresentation.checkingReadiness(),
          onRefresh: () => ref.invalidate(memoryOverviewProvider),
          onOpenGateway: () => _openGateway(context),
          onOpenActiveChat: () => _openActiveChat(context, activeProfile),
          child: const Center(child: CircularProgressIndicator()),
        ),
        error: (error, stackTrace) => _MemoryReadinessOnlyBody(
          scope: scope,
          readiness: _memoryPresentation.unavailableReadiness(
            message: 'Gormes memory API is unavailable.',
          ),
          onRefresh: () => ref.invalidate(memoryOverviewProvider),
          onOpenGateway: () => _openGateway(context),
          onOpenActiveChat: () => _openActiveChat(context, activeProfile),
        ),
        data: (overview) => _MemoryOverviewBody(
          overview: overview,
          presentation: _memoryPresentation.overviewFor(
            overview,
            activeProfile: activeProfile,
          ),
          scope: scope,
          readiness: _memoryPresentation.readinessFor(overview),
          onRefresh: () => ref.invalidate(memoryOverviewProvider),
          onOpenGateway: () => _openGateway(context),
          onOpenActiveChat: () => _openActiveChat(context, activeProfile),
        ),
      ),
    );
  }

  void _openGateway(BuildContext context) {
    GoRouter.maybeOf(context)?.go(AppRoutes.servers);
  }

  void _openActiveChat(
    BuildContext context,
    NavivoxProfileContact? activeProfile,
  ) {
    final contact = activeProfile;
    final location = contact == null
        ? AppRoutes.chats
        : AppRoutes.chatLocation(
            serverId: contact.serverId,
            profileId: contact.profileId,
          );
    GoRouter.maybeOf(context)?.go(location);
  }
}

class _MemoryReadinessOnlyBody extends StatelessWidget {
  const _MemoryReadinessOnlyBody({
    required this.scope,
    required this.readiness,
    required this.onRefresh,
    required this.onOpenGateway,
    required this.onOpenActiveChat,
    this.child,
  });

  final ProfileContactScopePresentation scope;
  final MemoryReadinessPresentation readiness;
  final VoidCallback onRefresh;
  final VoidCallback onOpenGateway;
  final VoidCallback onOpenActiveChat;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _MemoryReadinessCard(
          scope: scope,
          readiness: readiness,
          onRefresh: onRefresh,
          onOpenGateway: onOpenGateway,
          onOpenActiveChat: onOpenActiveChat,
        ),
        if (child != null) ...[const SizedBox(height: 24), child!],
      ],
    );
  }
}

class _MemoryReadinessCard extends StatelessWidget {
  const _MemoryReadinessCard({
    required this.scope,
    required this.readiness,
    required this.onRefresh,
    required this.onOpenGateway,
    required this.onOpenActiveChat,
  });

  final ProfileContactScopePresentation scope;
  final MemoryReadinessPresentation readiness;
  final VoidCallback onRefresh;
  final VoidCallback onOpenGateway;
  final VoidCallback onOpenActiveChat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
          label: Text(readiness.refreshLabel),
        ),
        TextButton.icon(
          onPressed: onOpenGateway,
          icon: const Icon(Icons.dns_outlined),
          label: Text(readiness.openGatewayLabel),
        ),
        TextButton.icon(
          onPressed: onOpenActiveChat,
          icon: const Icon(Icons.chat_bubble_outline),
          label: Text(readiness.openActiveChatLabel),
        ),
      ],
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(readiness.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(readiness.statusLabel),
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerRight, child: actions),
            const SizedBox(height: 6),
            Text(readiness.message),
            const SizedBox(height: 8),
            Text('Memory scope', style: theme.textTheme.titleSmall),
            Text('Active server: ${scope.serverLabel}'),
            Text('Active profile: ${scope.profileLabel}'),
            if (scope.profileId != null)
              Text('Active profile ID: ${scope.profileId}'),
          ],
        ),
      ),
    );
  }
}

class _MemoryOverviewBody extends StatelessWidget {
  const _MemoryOverviewBody({
    required this.overview,
    required this.presentation,
    required this.scope,
    required this.readiness,
    required this.onRefresh,
    required this.onOpenGateway,
    required this.onOpenActiveChat,
  });

  final NavivoxMemoryOverview overview;
  final MemoryOverviewPresentation presentation;
  final ProfileContactScopePresentation scope;
  final MemoryReadinessPresentation readiness;
  final VoidCallback onRefresh;
  final VoidCallback onOpenGateway;
  final VoidCallback onOpenActiveChat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _MemoryReadinessCard(
          scope: scope,
          readiness: readiness,
          onRefresh: onRefresh,
          onOpenGateway: onOpenGateway,
          onOpenActiveChat: onOpenActiveChat,
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      overview.isActive
                          ? Icons.psychology_alt
                          : Icons.warning_amber_outlined,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        presentation.healthLabel,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(presentation.serverLine),
                Text(presentation.profileLine),
                if (presentation.workspaceLine != null)
                  Text(presentation.workspaceLine!),
                Text(presentation.databaseTitle),
                SelectableText(presentation.databaseLabel),
                if (presentation.lastUpdatedLine != null)
                  Text(presentation.lastUpdatedLine!),
                if (presentation.degradedReason.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    presentation.degradedReason,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final count in presentation.counts)
              _MemoryCountCard(label: count.label, count: count.count),
          ],
        ),
        const SizedBox(height: 16),
        const _MemorySearchSection(),
      ],
    );
  }
}

class _MemorySearchSection extends ConsumerStatefulWidget {
  const _MemorySearchSection();

  @override
  ConsumerState<_MemorySearchSection> createState() =>
      _MemorySearchSectionState();
}

class _MemorySearchSectionState extends ConsumerState<_MemorySearchSection> {
  String _query = '';
  NavivoxMemoryType _selectedType = NavivoxMemoryType.all;
  late Future<NavivoxMemorySearchResult> _results;

  @override
  void initState() {
    super.initState();
    _results = _load();
  }

  Future<NavivoxMemorySearchResult> _load() {
    final channel = ref.read(navivoxChannelProvider);
    final request = _memoryActions.searchRequest(
      activeProfile: channel.state.activeProfileContact,
      query: _query,
      type: _selectedType,
    );
    return channel.memorySearch(
      serverId: request.scope.serverId,
      profileId: request.scope.profileId,
      query: request.query,
      type: request.type,
      limit: request.limit,
    );
  }

  void _refresh({String? query, NavivoxMemoryType? type}) {
    setState(() {
      if (query != null) _query = query.trim();
      if (type != null) _selectedType = type;
      _results = _load();
    });
  }

  void _showMemoryDetail(BuildContext context, NavivoxMemoryItem item) {
    final channel = ref.read(navivoxChannelProvider);
    final request = _memoryActions.detailRequest(
      activeProfile: channel.state.activeProfileContact,
      item: item,
    );
    final detail = channel.memoryDetail(
      serverId: request.scope.serverId,
      profileId: request.scope.profileId,
      id: request.id,
      type: request.type,
    );
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _MemoryDetailSheet(detail: detail),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _memoryPresentation.searchTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: _memoryPresentation.searchFieldLabel,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) => _refresh(query: value),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final type in NavivoxMemoryType.values)
                  ChoiceChip(
                    label: Text(type.label),
                    selected: _selectedType == type,
                    onSelected: (_) => _refresh(type: type),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<NavivoxMemorySearchResult>(
              future: _results,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _MemorySearchMessage(
                    icon: Icons.warning_amber_outlined,
                    message: _memoryPresentation.searchUnavailableMessage,
                  );
                }
                final result =
                    snapshot.data ??
                    NavivoxMemorySearchResult.degraded(
                      reason: _memoryPresentation.searchUnavailableMessage,
                    );
                if (result.isDegraded) {
                  return _MemorySearchMessage(
                    icon: Icons.warning_amber_outlined,
                    message: result.degradedReason,
                  );
                }
                if (result.items.isEmpty) {
                  return _MemorySearchMessage(
                    icon: Icons.manage_search,
                    message: _memoryPresentation.emptySearchMessage,
                  );
                }
                return Column(
                  children: [
                    for (final item in result.items)
                      _MemoryItemCard(
                        presentation: _memoryPresentation.itemFor(item),
                        onTap: () => _showMemoryDetail(context, item),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MemoryItemCard extends StatelessWidget {
  const _MemoryItemCard({required this.presentation, required this.onTap});

  final MemoryItemPresentation presentation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      key: ValueKey(presentation.keyValue),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        onTap: onTap,
        title: Text(presentation.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (presentation.metadataLine != null)
              Text(presentation.metadataLine!),
            if (presentation.tags.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final tag in presentation.tags)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(tag),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MemoryDetailSheet extends ConsumerWidget {
  const _MemoryDetailSheet({required this.detail});

  final Future<NavivoxMemoryDetail> detail;

  Future<void> _requestAction(
    BuildContext context,
    WidgetRef ref,
    NavivoxMemoryDetail item,
    NavivoxMemoryActionType action, {
    String? correction,
  }) async {
    final channel = ref.read(navivoxChannelProvider);
    final request = _memoryActions.actionRequest(
      activeProfile: channel.state.activeProfileContact,
      item: item,
      action: action,
      correction: correction,
    );
    final result = await channel.memoryAction(
      serverId: request.scope.serverId,
      profileId: request.scope.profileId,
      id: request.id,
      type: request.type,
      action: request.action,
      correction: request.correction,
    );
    if (!context.mounted) return;
    _applyMemoryActionEffect(
      context,
      _memoryActions.afterAction(
        result,
        requestedAction: action,
        messageFor: _memoryPresentation.actionMessageFor,
      ),
    );
  }

  void _applyMemoryActionEffect(
    BuildContext context,
    MemoryActionEffect effect,
  ) {
    switch (effect) {
      case ShowMemorySnackbarEffect(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _requestCorrection(
    BuildContext context,
    WidgetRef ref,
    NavivoxMemoryDetail item,
  ) async {
    var note = '';
    final correction = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_memoryPresentation.correctionDialogTitle),
        content: TextField(
          autofocus: true,
          decoration: InputDecoration(
            labelText: _memoryPresentation.correctionFieldLabel,
            helperText: _memoryPresentation.correctionFieldHelperText,
          ),
          maxLines: 3,
          onChanged: (value) => note = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(_memoryPresentation.cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(note),
            child: Text(_memoryPresentation.saveCorrectionLabel),
          ),
        ],
      ),
    );
    final trimmed = correction?.trim();
    if (trimmed == null || trimmed.isEmpty || !context.mounted) return;
    await _requestAction(
      context,
      ref,
      item,
      NavivoxMemoryActionType.addCorrection,
      correction: trimmed,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: FutureBuilder<NavivoxMemoryDetail>(
        future: detail,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final item = snapshot.data;
          if (snapshot.hasError || item == null || item.isDegraded) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                item?.degradedReason ??
                    _memoryPresentation.detailUnavailableMessage,
              ),
            );
          }
          final presentation = _memoryPresentation.detailFor(item);
          return ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Text(
                presentation.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              SelectableText(presentation.content),
              const SizedBox(height: 12),
              for (final row in presentation.rows) _DetailLine(row: row),
              if (presentation.provenance.isNotEmpty) ...[
                const Divider(),
                Text(
                  presentation.provenanceTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SelectableText(presentation.provenance),
              ],
              if (presentation.linkedEntities.isNotEmpty) ...[
                const Divider(),
                Text(
                  presentation.linkedEntitiesTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final entity in presentation.linkedEntities) Text(entity),
              ],
              if (presentation.linkedRelationships.isNotEmpty) ...[
                const Divider(),
                Text(
                  presentation.linkedRelationshipsTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final relationship in presentation.linkedRelationships)
                  Text(relationship),
              ],
              const Divider(),
              Text(presentation.rawSourcePreservedLabel),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final action in presentation.actions)
                    OutlinedButton(
                      onPressed: action.requiresCorrection
                          ? () => _requestCorrection(context, ref, item)
                          : () =>
                                _requestAction(context, ref, item, action.type),
                      child: Text(action.label),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.row});

  final MemoryDetailLinePresentation row;

  @override
  Widget build(BuildContext context) {
    return Text(row.line);
  }
}

class _MemorySearchMessage extends StatelessWidget {
  const _MemorySearchMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _MemoryCountCard extends StatelessWidget {
  const _MemoryCountCard({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count.toString(),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
