import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/channel/navivox_channel.dart';
import '../../../core/channel/navivox_channel_provider.dart';
import '../../../router/app_routes.dart';
import '../../profile_contacts/profile_contact_avatar.dart';
import '../../profile_contacts/profile_contact_list_presentation.dart';
import '../../profile_contacts/profile_contact_presentation.dart';
import '../../profiles/profile_seed_sheet.dart';

const _profileContactsPresentation = ProfileContactsScreenPresentation();

class ProfileContactsScreen extends ConsumerStatefulWidget {
  const ProfileContactsScreen({super.key});

  @override
  ConsumerState<ProfileContactsScreen> createState() =>
      _ProfileContactsScreenState();
}

class _ProfileContactsScreenState extends ConsumerState<ProfileContactsScreen> {
  NavivoxChannel? _subscribed;
  final _searchController = TextEditingController();
  bool _searching = false;
  String _query = '';
  String? _selectedServerId;

  void _onChannelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _subscribed?.removeListener(_onChannelChanged);
    _searchController.dispose();
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

    final presentation = ProfileContactListPresentation.fromContacts(
      servers: channel.state.servers,
      contacts: channel.state.profileContacts,
      selectedServerId: _selectedServerId,
      query: _query,
    );

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                key: const ValueKey('profile-search-field'),
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: _profileContactsPresentation.searchHint,
                  border: InputBorder.none,
                ),
                onChanged: (value) => setState(() => _query = value),
              )
            : Text(_profileContactsPresentation.title),
        actions: [
          IconButton(
            tooltip: _searching
                ? _profileContactsPresentation.closeSearchTooltip
                : _profileContactsPresentation.searchTooltip,
            onPressed: _toggleSearch,
            icon: Icon(_searching ? Icons.close : Icons.search),
          ),
          IconButton(
            tooltip: _profileContactsPresentation.manageGatewaysTooltip,
            onPressed: () => context.go(AppRoutes.servers),
            icon: const Icon(Icons.dns),
          ),
        ],
      ),
      body: !presentation.hasContacts
          ? Center(child: Text(_profileContactsPresentation.noProfilesMessage))
          : Column(
              children: [
                if (presentation.showServerFilter) ...[
                  _ServerFilterBar(
                    servers: presentation.servers,
                    selectedServerId: presentation.selectedServerId,
                    visibleCountLabel: presentation.visibleCountLabel,
                    allServersLabel:
                        _profileContactsPresentation.allServersLabel,
                    onSelected: (serverId) => setState(() {
                      _selectedServerId = serverId;
                    }),
                  ),
                  const Divider(height: 1),
                ],
                Expanded(
                  child: !presentation.hasVisibleContacts
                      ? Center(
                          child: Text(
                            _profileContactsPresentation.noVisibleChatsMessage,
                          ),
                        )
                      : ListView.separated(
                          itemCount: presentation.visibleContacts.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final contact = presentation.visibleContacts[index];
                            return _ProfileContactTile(
                              contact: contact,
                              query: _query,
                              selected:
                                  contact.key ==
                                  channel.state.selectedProfileContactKey,
                              onTap: () {
                                channel.selectProfileContact(
                                  serverId: contact.serverId,
                                  profileId: contact.profileId,
                                );
                                context.go(
                                  AppRoutes.chatLocation(
                                    serverId: contact.serverId,
                                    profileId: contact.profileId,
                                  ),
                                );
                              },
                              onLongPress: () =>
                                  _showProfileDetails(context, contact),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.small(
        tooltip: _profileContactsPresentation.addProfileTooltip,
        onPressed: () => _showAddProfilePlaceholder(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _query = '';
        _searchController.clear();
      }
    });
  }

  void _showAddProfilePlaceholder(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              key: const ValueKey('profile-create-from-seed'),
              leading: const Icon(Icons.auto_awesome),
              title: const Text('Create from seed'),
              subtitle: const Text(
                'Ask Gormes to draft a profile from natural language.',
              ),
              onTap: () {
                Navigator.of(context).pop();
                _showProfileSeedSheet(context);
              },
            ),
            for (final row in _profileContactsPresentation.addProfileRows)
              ListTile(
                leading: Icon(_addProfileRowIcon(row.kind)),
                title: Text(row.title),
                subtitle: Text(row.subtitle),
              ),
          ],
        ),
      ),
    );
  }

  void _showProfileSeedSheet(BuildContext context) {
    final channel = ref.read(navivoxChannelProvider);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => ProfileSeedSheet(channel: channel),
    );
  }

  void _showProfileDetails(
    BuildContext context,
    NavivoxProfileContact contact,
  ) {
    final channel = ref.read(navivoxChannelProvider);
    final summary = ProfileContactPresentation(contact);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: ProfileContactAvatar(contact: contact),
              title: Text(summary.detailsTitle),
              subtitle: Text(summary.detailsSubtitle),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.monitor_heart_outlined),
              title: Text(summary.diagnosticsTitle),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 72, right: 16, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final line in summary.diagnosticLines) Text(line),
                ],
              ),
            ),
            const Divider(height: 1),
            for (final section in summary.detailSections)
              _ProfileDetailSection(
                icon: _detailSectionIcon(section.kind),
                title: section.title,
                lines: section.lines,
              ),
            const Divider(height: 1),
            for (final action in summary.detailActions)
              ListTile(
                leading: Icon(_detailActionIcon(action.kind)),
                title: Text(action.title),
                subtitle: Text(action.subtitle),
                onTap: () => _handleProfileDetailAction(
                  context,
                  channel,
                  contact,
                  action.kind,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleProfileDetailAction(
    BuildContext context,
    NavivoxChannel channel,
    NavivoxProfileContact contact,
    ProfileContactDetailActionKind kind,
  ) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    switch (kind) {
      case ProfileContactDetailActionKind.openChat:
        channel.selectProfileContact(
          serverId: contact.serverId,
          profileId: contact.profileId,
        );
        router.go(
          AppRoutes.chatLocation(
            serverId: contact.serverId,
            profileId: contact.profileId,
          ),
        );
      case ProfileContactDetailActionKind.openMemory:
        channel.selectProfileContact(
          serverId: contact.serverId,
          profileId: contact.profileId,
        );
        router.go(AppRoutes.memory);
      case ProfileContactDetailActionKind.editProfile:
        channel.selectProfileContact(
          serverId: contact.serverId,
          profileId: contact.profileId,
        );
        router.go(AppRoutes.config);
    }
  }
}

class _ProfileDetailSection extends StatelessWidget {
  const _ProfileDetailSection({
    required this.icon,
    required this.title,
    required this.lines,
  });

  final IconData icon;
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          for (final line in lines) Text(line),
        ],
      ),
    );
  }
}

class _ServerFilterBar extends StatelessWidget {
  const _ServerFilterBar({
    required this.servers,
    required this.selectedServerId,
    required this.visibleCountLabel,
    required this.allServersLabel,
    required this.onSelected,
  });

  final List<NavivoxServer> servers;
  final String? selectedServerId;
  final String visibleCountLabel;
  final String allServersLabel;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          ChoiceChip(
            key: const ValueKey('server-filter-all'),
            label: Text(allServersLabel),
            selected: selectedServerId == null,
            onSelected: (_) => onSelected(null),
          ),
          const SizedBox(width: 8),
          for (final server in servers) ...[
            ChoiceChip(
              key: ValueKey('server-filter-${server.id}'),
              label: Text(server.name),
              selected: selectedServerId == server.id,
              onSelected: (_) => onSelected(server.id),
            ),
            const SizedBox(width: 8),
          ],
          Center(
            child: Text(
              visibleCountLabel,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSearchHighlightText extends StatelessWidget {
  const _ProfileSearchHighlightText({
    required this.text,
    required this.query,
    this.style,
    this.maxLines,
    this.overflow,
    super.key,
  });

  final String text;
  final String query;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ?? DefaultTextStyle.of(context).style;
    final normalizedQuery = query.trim().toLowerCase();
    final start = normalizedQuery.isEmpty
        ? -1
        : text.toLowerCase().indexOf(normalizedQuery);
    if (start < 0) {
      return Text(
        text,
        style: effectiveStyle,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final end = start + normalizedQuery.length;
    final accent = Theme.of(context).colorScheme.primary;
    return Text.rich(
      TextSpan(
        style: effectiveStyle,
        children: [
          if (start > 0) TextSpan(text: text.substring(0, start)),
          TextSpan(
            text: text.substring(start, end),
            style: effectiveStyle.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (end < text.length) TextSpan(text: text.substring(end)),
        ],
      ),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

class _ProfileContactAvatarStack extends StatelessWidget {
  const _ProfileContactAvatarStack({required this.contact});

  final NavivoxProfileContact contact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOnline = contact.health == NavivoxProfileHealth.online;
    final voiceReady = contact.micAvailable && contact.voiceCapability.enabled;
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: ProfileContactAvatar(contact: contact)),
          if (isOnline)
            Positioned(
              key: ValueKey(
                'profile-contact-presence-${contact.serverId}-${contact.profileId}',
              ),
              right: 1,
              bottom: 1,
              child: Semantics(
                label: '${contact.displayName} online',
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green.shade500,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          if (voiceReady)
            Positioned(
              key: ValueKey(
                'profile-contact-voice-ready-${contact.serverId}-${contact.profileId}',
              ),
              right: -2,
              top: -2,
              child: Semantics(
                label: '${contact.displayName} voice ready',
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.mic,
                    size: 9,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileTypingDots extends StatelessWidget {
  const _ProfileTypingDots({required this.contact});

  final NavivoxProfileContact contact;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < 3; index += 1) ...[
          Container(
            key: ValueKey(
              'profile-typing-dot-${contact.serverId}-${contact.profileId}-$index',
            ),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.55 + index * 0.15),
              shape: BoxShape.circle,
            ),
          ),
          if (index < 2) const SizedBox(width: 2),
        ],
      ],
    );
  }
}

class _ProfileContactTile extends StatelessWidget {
  const _ProfileContactTile({
    required this.contact,
    required this.query,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  final NavivoxProfileContact contact;
  final String query;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final summary = ProfileContactPresentation(contact);
    return ListTile(
      key: ValueKey('profile-contact-${contact.serverId}-${contact.profileId}'),
      selected: selected,
      selectedTileColor: Theme.of(
        context,
      ).colorScheme.primaryContainer.withValues(alpha: 0.32),
      leading: _ProfileContactAvatarStack(contact: contact),
      title: Row(
        children: [
          Expanded(
            child: _ProfileSearchHighlightText(
              key: ValueKey(
                'profile-contact-title-${contact.serverId}-${contact.profileId}',
              ),
              text: contact.displayName,
              query: query,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          _ServerChip(label: contact.serverLabel),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _ProfileSearchHighlightText(
                  key: ValueKey(
                    'profile-contact-preview-${contact.serverId}-${contact.profileId}',
                  ),
                  text: summary.latestLabel,
                  query: query,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: contact.activeTurnState == 'streaming'
                      ? TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontStyle: FontStyle.italic,
                        )
                      : null,
                ),
              ),
              if (contact.activeTurnState == 'streaming') ...[
                Container(
                  key: ValueKey(
                    'profile-active-turn-${contact.serverId}-${contact.profileId}',
                  ),
                  margin: const EdgeInsets.only(left: 6),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                _ProfileTypingDots(contact: contact),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _HealthChip(summary: summary),
              Text(
                summary.workspaceLabel,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              for (final badge in contact.attentionBadges)
                Chip(visualDensity: VisualDensity.compact, label: Text(badge)),
            ],
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (summary.latestTimeLabel.isNotEmpty)
            Text(
              summary.latestTimeLabel,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                contact.micAvailable ? Icons.mic : Icons.mic_off,
                size: 16,
                color: contact.micAvailable
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).disabledColor,
              ),
              if (summary.attentionCount > 0) ...[
                const SizedBox(width: 4),
                _AttentionCountBadge(
                  key: ValueKey(
                    'profile-attention-${contact.serverId}-${contact.profileId}',
                  ),
                  count: summary.attentionCount,
                ),
              ],
            ],
          ),
        ],
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}

IconData _addProfileRowIcon(ProfileContactsAddRowKind kind) {
  return switch (kind) {
    ProfileContactsAddRowKind.newProfile => Icons.person_add_alt,
    ProfileContactsAddRowKind.addServer => Icons.dns,
  };
}

IconData _detailSectionIcon(ProfileContactDetailSectionKind kind) {
  return switch (kind) {
    ProfileContactDetailSectionKind.identity => Icons.badge_outlined,
    ProfileContactDetailSectionKind.channels => Icons.forum_outlined,
    ProfileContactDetailSectionKind.memory => Icons.psychology_alt_outlined,
    ProfileContactDetailSectionKind.skills => Icons.extension_outlined,
    ProfileContactDetailSectionKind.config =>
      Icons.settings_applications_outlined,
    ProfileContactDetailSectionKind.logs => Icons.article_outlined,
  };
}

IconData _detailActionIcon(ProfileContactDetailActionKind kind) {
  return switch (kind) {
    ProfileContactDetailActionKind.openChat => Icons.chat_bubble_outline,
    ProfileContactDetailActionKind.openMemory => Icons.psychology_alt_outlined,
    ProfileContactDetailActionKind.editProfile => Icons.edit,
  };
}

class _AttentionCountBadge extends StatelessWidget {
  const _AttentionCountBadge({required this.count, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$count attention ${count == 1 ? 'item' : 'items'}',
      child: Container(
        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          count.toString(),
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onError,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ServerChip extends StatelessWidget {
  const _ServerChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(visualDensity: VisualDensity.compact, label: Text(label));
  }
}

class _HealthChip extends StatelessWidget {
  const _HealthChip({required this.summary});

  final ProfileContactPresentation summary;

  @override
  Widget build(BuildContext context) {
    return Text(
      summary.compactHealthLabel,
      style: Theme.of(context).textTheme.labelSmall,
    );
  }
}
