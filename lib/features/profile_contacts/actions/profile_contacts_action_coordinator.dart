import '../../../core/channel/navivox_channel.dart';
import '../../../router/navigation_intent.dart';
import '../presentation/profile_contact_presentation.dart';

/// Maps Profile contact screen operator actions to typed UI/channel effects.
///
/// The screen still owns Flutter concerns: modal rendering, setState,
/// NavigationIntent execution, and channel calls.
final class ProfileContactsActionCoordinator {
  const ProfileContactsActionCoordinator();

  List<ProfileContactsEffect> selectContact(NavivoxProfileContact contact) {
    return [
      ProfileContactsEffect.selectContact(contact),
      ProfileContactsEffect.navigate(
        OpenChatThread(contact.serverId, contact.profileId),
      ),
    ];
  }

  List<ProfileContactsEffect> menu(ProfileContactsMenuActionKind action) {
    return [
      ProfileContactsEffect.navigate(switch (action) {
        ProfileContactsMenuActionKind.manageGateways => const OpenGateways(),
        ProfileContactsMenuActionKind.manageProfiles => const OpenAgents(),
        ProfileContactsMenuActionKind.openMemory => const OpenWorkspace(),
        ProfileContactsMenuActionKind.openConfig => const OpenConfig(),
        ProfileContactsMenuActionKind.openSettings => const OpenSettings(),
      }),
    ];
  }

  List<ProfileContactsEffect> addProfile(ProfileContactsAddRowKind kind) {
    return switch (kind) {
      ProfileContactsAddRowKind.newProfile => const [
        ProfileContactsEffect.showProfileSeedSheet(),
      ],
      ProfileContactsAddRowKind.addServer => const [
        ProfileContactsEffect.navigate(OpenGateways()),
      ],
    };
  }

  List<ProfileContactsEffect> detailAction(
    NavivoxProfileContact contact,
    ProfileContactDetailActionKind kind,
  ) {
    return [
      const ProfileContactsEffect.dismissModal(),
      ProfileContactsEffect.selectContact(contact),
      ProfileContactsEffect.navigate(switch (kind) {
        ProfileContactDetailActionKind.openChat => OpenChatThread(
          contact.serverId,
          contact.profileId,
        ),
        ProfileContactDetailActionKind.openMemory => const OpenWorkspace(),
        ProfileContactDetailActionKind.editProfile => const OpenConfig(),
      }),
    ];
  }
}

sealed class ProfileContactsEffect {
  const ProfileContactsEffect._();

  const factory ProfileContactsEffect.selectContact(
    NavivoxProfileContact contact,
  ) = SelectProfileContactEffect;

  const factory ProfileContactsEffect.navigate(NavigationIntent intent) =
      NavigateProfileContactsEffect;

  const factory ProfileContactsEffect.showProfileSeedSheet() =
      ShowProfileSeedSheetEffect;

  const factory ProfileContactsEffect.dismissModal() =
      DismissProfileContactsModalEffect;
}

final class SelectProfileContactEffect extends ProfileContactsEffect {
  const SelectProfileContactEffect(this.contact) : super._();

  final NavivoxProfileContact contact;
}

final class NavigateProfileContactsEffect extends ProfileContactsEffect {
  const NavigateProfileContactsEffect(this.intent) : super._();

  final NavigationIntent intent;
}

final class ShowProfileSeedSheetEffect extends ProfileContactsEffect {
  const ShowProfileSeedSheetEffect() : super._();
}

final class DismissProfileContactsModalEffect extends ProfileContactsEffect {
  const DismissProfileContactsModalEffect() : super._();
}
