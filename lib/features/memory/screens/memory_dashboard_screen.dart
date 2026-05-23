import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/channel/navivox_channel_provider.dart';
import '../../../core/protocol/navivox_memory.dart';
import '../memory_dashboard_presentation.dart';

const _memoryPresentation = MemoryDashboardPresentation();

final memoryOverviewProvider =
    FutureProvider.autoDispose<NavivoxMemoryOverview>((ref) {
      final channel = ref.watch(navivoxChannelProvider);
      final activeProfile = channel.state.activeProfileContact;
      return channel.memoryOverview(
        serverId: activeProfile?.serverId,
        profileId: activeProfile?.profileId,
      );
    });

class MemoryDashboardScreen extends ConsumerWidget {
  const MemoryDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channel = ref.watch(navivoxChannelProvider);
    final activeProfile = channel.state.activeProfileContact;
    final overview = ref.watch(memoryOverviewProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_memoryPresentation.title)),
      body: overview.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _MemoryError(
          presentation: _memoryPresentation.errorFor(
            activeProfile,
            message: 'Gormes memory API is unavailable.',
          ),
        ),
        data: (overview) => _MemoryOverviewBody(
          overview: overview,
          presentation: _memoryPresentation.overviewFor(
            overview,
            activeProfile: activeProfile,
          ),
        ),
      ),
    );
  }
}

class _MemoryOverviewBody extends StatelessWidget {
  const _MemoryOverviewBody({
    required this.overview,
    required this.presentation,
  });

  final NavivoxMemoryOverview overview;
  final MemoryOverviewPresentation presentation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
    final activeProfile = channel.state.activeProfileContact;
    return channel.memorySearch(
      serverId: activeProfile?.serverId,
      profileId: activeProfile?.profileId,
      query: _query,
      type: _selectedType,
      limit: 20,
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
    final activeProfile = channel.state.activeProfileContact;
    final detail = channel.memoryDetail(
      serverId: activeProfile?.serverId,
      profileId: activeProfile?.profileId,
      id: item.id,
      type: item.type,
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
    final activeProfile = channel.state.activeProfileContact;
    final result = await channel.memoryAction(
      serverId: activeProfile?.serverId,
      profileId: activeProfile?.profileId,
      id: item.id,
      type: item.type,
      action: action,
      correction: correction,
    );
    if (!context.mounted) return;
    final message = _memoryPresentation.actionMessageFor(
      result,
      requestedAction: action,
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

class _MemoryError extends StatelessWidget {
  const _MemoryError({required this.presentation});

  final MemoryErrorPresentation presentation;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_outlined, size: 40),
            const SizedBox(height: 12),
            Text(
              presentation.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(presentation.profileLine),
            const SizedBox(height: 8),
            Text(presentation.message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
