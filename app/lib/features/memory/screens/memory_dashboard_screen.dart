import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/channel/navivox_channel.dart';
import '../../../core/channel/navivox_channel_provider.dart';
import '../../../core/protocol/navivox_memory.dart';

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
      appBar: AppBar(title: const Text('Memory')),
      body: overview.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _MemoryError(
          profileLabel: _profileLabel(activeProfile, fallback: 'default'),
          message: 'Gormes memory API is unavailable.',
        ),
        data: (overview) => _MemoryOverviewBody(
          overview: overview,
          profileLabel: _profileLabel(
            activeProfile,
            fallback: overview.profileId,
          ),
        ),
      ),
    );
  }
}

class _MemoryOverviewBody extends StatelessWidget {
  const _MemoryOverviewBody({
    required this.overview,
    required this.profileLabel,
  });

  final NavivoxMemoryOverview overview;
  final String profileLabel;

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
                        overview.healthLabel,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Profile: $profileLabel'),
                if (overview.workspaceId.isNotEmpty)
                  Text('Workspace: ${overview.workspaceId}'),
                const Text('Database'),
                SelectableText(overview.databaseLabel),
                if (overview.lastUpdatedAt != null)
                  Text(
                    'Last updated: ${overview.lastUpdatedAt!.toUtc().toIso8601String()}',
                  ),
                if (overview.degradedReason.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    overview.degradedReason,
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
            _MemoryCountCard(label: 'Turns', count: overview.totalTurns),
            _MemoryCountCard(
              label: 'Active memory items',
              count: overview.activeMemoryItems,
            ),
            _MemoryCountCard(
              label: 'Observations',
              count: overview.observations,
            ),
            _MemoryCountCard(label: 'Conclusions', count: overview.conclusions),
            _MemoryCountCard(
              label: 'Session summaries',
              count: overview.sessionSummaries,
            ),
            _MemoryCountCard(label: 'Entities', count: overview.entities),
            _MemoryCountCard(
              label: 'Relationships',
              count: overview.relationships,
            ),
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

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search & Browse',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Search memories',
                prefixIcon: Icon(Icons.search),
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
                  return const _MemorySearchMessage(
                    icon: Icons.warning_amber_outlined,
                    message: 'Gormes memory search API is unavailable.',
                  );
                }
                final result =
                    snapshot.data ??
                    const NavivoxMemorySearchResult.degraded(
                      reason: 'Gormes memory search API is unavailable.',
                    );
                if (result.isDegraded) {
                  return _MemorySearchMessage(
                    icon: Icons.warning_amber_outlined,
                    message: result.degradedReason,
                  );
                }
                if (result.items.isEmpty) {
                  return const _MemorySearchMessage(
                    icon: Icons.manage_search,
                    message: 'No memories found.',
                  );
                }
                return Column(
                  children: [
                    for (final item in result.items)
                      _MemoryItemCard(item: item),
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
  const _MemoryItemCard({required this.item});

  final NavivoxMemoryItem item;

  @override
  Widget build(BuildContext context) {
    final metadata = [
      item.type.wireValue,
      item.status,
      item.sessionId,
      item.peerId,
    ].where((value) => value.trim().isNotEmpty).join(' · ');
    return Card.outlined(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: Text(item.snippet),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (metadata.isNotEmpty) Text(metadata),
            if (item.tags.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final tag in item.tags)
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
  const _MemoryError({required this.profileLabel, required this.message});

  final String profileLabel;
  final String message;

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
              'Goncho degraded',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Profile: $profileLabel'),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

String _profileLabel(
  NavivoxProfileContact? contact, {
  required String fallback,
}) {
  final displayName = contact?.displayName.trim();
  if (displayName != null && displayName.isNotEmpty) return displayName;
  return fallback;
}
