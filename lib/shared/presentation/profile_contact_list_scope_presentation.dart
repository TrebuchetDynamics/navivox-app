import '../../core/channel/navivox_channel.dart';
import 'profile_contact_labels.dart';

/// Shared profile-contact list contract for features that need server/query
/// filtering without depending on the profile-contacts feature presentation.
class ProfileContactListScopePresentation {
  const ProfileContactListScopePresentation({
    required this.servers,
    required this.allContacts,
    required this.visibleContacts,
    required this.selectedServerId,
  });

  factory ProfileContactListScopePresentation.fromContacts({
    required List<NavivoxServer> servers,
    required List<NavivoxProfileContact> contacts,
    String? selectedServerId,
    String query = '',
  }) {
    final sortedContacts = [...contacts]
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
    final normalizedQuery = query.trim().toLowerCase();
    final visibleContacts = sortedContacts
        .where(
          (contact) =>
              selectedServerId == null || contact.serverId == selectedServerId,
        )
        .where(
          (contact) =>
              normalizedQuery.isEmpty ||
              profileContactSearchTerms(
                contact,
              ).any((field) => field.toLowerCase().contains(normalizedQuery)),
        )
        .toList(growable: false);

    return ProfileContactListScopePresentation(
      servers: List.unmodifiable(servers),
      allContacts: List.unmodifiable(sortedContacts),
      visibleContacts: visibleContacts,
      selectedServerId: selectedServerId,
    );
  }

  final List<NavivoxServer> servers;
  final List<NavivoxProfileContact> allContacts;
  final List<NavivoxProfileContact> visibleContacts;
  final String? selectedServerId;

  bool get hasContacts => allContacts.isNotEmpty;
  bool get hasVisibleContacts => visibleContacts.isNotEmpty;
  bool get showServerFilter => servers.length > 1;

  String get visibleCountLabel {
    final count = visibleContacts.length;
    return count == 1 ? '1 profile' : '$count profiles';
  }
}
