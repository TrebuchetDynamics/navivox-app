import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/channel/navivox_channel.dart';
import '../../../core/channel/navivox_channel_provider.dart';
import '../../profile_contacts/profile_contact_avatar.dart';
import '../../profile_contacts/profile_contact_presentation.dart';
import '../agents_screen_presentation.dart';

class AgentsScreen extends ConsumerStatefulWidget {
  const AgentsScreen({super.key});

  @override
  ConsumerState<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends ConsumerState<AgentsScreen> {
  NavivoxChannel? _subscribed;

  void _onChannelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _subscribed?.removeListener(_onChannelChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final channel = ref.watch(navivoxChannelProvider);
    if (!identical(_subscribed, channel)) {
      _subscribed?.removeListener(_onChannelChanged);
      channel.addListener(_onChannelChanged);
      _subscribed = channel;
    }

    final presentation = AgentsScreenPresentation.fromState(channel.state);

    return Scaffold(
      appBar: AppBar(
        title: Text(presentation.screenTitle),
        actions: [
          IconButton(
            tooltip: presentation.refreshProfilesTooltip,
            onPressed: channel.requestAgentList,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: presentation.showAgentList
          ? _AgentList(
              agents: presentation.agents,
              selectedId: presentation.selectedAgentId,
              onSelected: channel.selectAgent,
            )
          : presentation.showProfileFallback
          ? _ProfileList(
              title: presentation.profileFallbackTitle,
              subtitle: presentation.profileFallbackSubtitle,
              profiles: presentation.profileContacts,
              selectedKey: presentation.selectedProfileContactKey,
              onSelected: (profile) => channel.selectProfileContact(
                serverId: profile.serverId,
                profileId: profile.profileId,
              ),
            )
          : _EmptyProfileState(
              title: presentation.emptyProfilesTitle,
              subtitle: presentation.emptyProfilesSubtitle,
              refreshLabel: presentation.refreshProfilesLabel,
              createImportLabel: presentation.createImportProfileLabel,
              onRefresh: channel.requestAgentList,
              onCreateImport: () =>
                  _showCreateImportUnavailableSheet(context, presentation),
            ),
    );
  }

  void _showCreateImportUnavailableSheet(
    BuildContext context,
    AgentsScreenPresentation presentation,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.person_add_alt),
              title: Text(presentation.createImportProfileSheetTitle),
              subtitle: Text(presentation.createImportProfileSheetSubtitle),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgentList extends StatelessWidget {
  const _AgentList({
    required this.agents,
    required this.selectedId,
    required this.onSelected,
  });

  final List<NavivoxAgent> agents;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        for (final agent in agents)
          ListTile(
            leading: const Icon(Icons.smart_toy),
            title: Text(agent.name),
            subtitle: Text(agent.status),
            trailing: agent.id == selectedId ? const Icon(Icons.check) : null,
            onTap: () => onSelected(agent.id),
          ),
      ],
    );
  }
}

class _ProfileList extends StatelessWidget {
  const _ProfileList({
    required this.title,
    required this.subtitle,
    required this.profiles,
    required this.selectedKey,
    required this.onSelected,
  });

  final String title;
  final String subtitle;
  final List<NavivoxProfileContact> profiles;
  final String? selectedKey;
  final ValueChanged<NavivoxProfileContact> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: profiles.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.people_alt_outlined),
              title: Text(title),
              subtitle: Text(subtitle),
            ),
          );
        }
        final profile = profiles[index - 1];
        final active = profile.key == selectedKey;
        return Card(
          child: ListTile(
            key: ValueKey(
              'agent-profile-${profile.serverId}-${profile.profileId}',
            ),
            leading: ProfileContactAvatar(contact: profile),
            title: Text(profile.displayName),
            subtitle: _ProfileSummary(profile: profile),
            trailing: active
                ? const Icon(
                    Icons.check_circle,
                    semanticLabel: 'Active profile',
                  )
                : null,
            onTap: () => onSelected(profile),
          ),
        );
      },
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({required this.profile});

  final NavivoxProfileContact profile;

  @override
  Widget build(BuildContext context) {
    final summary = ProfileContactPresentation(profile);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in summary.agentFallbackSummaryLines) Text(line),
      ],
    );
  }
}

class _EmptyProfileState extends StatelessWidget {
  const _EmptyProfileState({
    required this.title,
    required this.subtitle,
    required this.refreshLabel,
    required this.createImportLabel,
    required this.onRefresh,
    required this.onCreateImport,
  });

  final String title;
  final String subtitle;
  final String refreshLabel;
  final String createImportLabel;
  final VoidCallback onRefresh;
  final VoidCallback onCreateImport;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_alt_outlined, size: 48),
            const SizedBox(height: 12),
            Text(title),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: Text(refreshLabel),
            ),
            TextButton.icon(
              onPressed: onCreateImport,
              icon: const Icon(Icons.person_add_alt),
              label: Text(createImportLabel),
            ),
          ],
        ),
      ),
    );
  }
}
