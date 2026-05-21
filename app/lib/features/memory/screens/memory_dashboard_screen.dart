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
      ],
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
