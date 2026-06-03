import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/features/profile_contacts/actions/profile_contacts_action_coordinator.dart';
import 'package:navivox/features/profile_contacts/presentation/profile_contact_presentation.dart';
import 'package:navivox/router/navigation_intent.dart';

void main() {
  const coordinator = ProfileContactsActionCoordinator();
  const contact = NavivoxProfileContact(
    serverId: 'gateway-1',
    profileId: 'profile-1',
    displayName: 'Profile 1',
    serverLabel: 'Gateway 1',
    health: NavivoxProfileHealth.online,
    latestPreview: 'Ready',
  );

  test('select contact emits selection before chat navigation', () {
    final effects = coordinator.selectContact(contact);

    expect(effects[0], isA<SelectProfileContactEffect>());
    expect((effects[0] as SelectProfileContactEffect).contact, contact);
    expect(effects[1], isA<NavigateProfileContactsEffect>());
    expect(
      (effects[1] as NavigateProfileContactsEffect).intent,
      isA<OpenChatThread>(),
    );
  });

  test('menu actions map to navigation intents', () {
    expect(
      (coordinator.menu(ProfileContactsMenuActionKind.manageGateways).single
              as NavigateProfileContactsEffect)
          .intent,
      isA<OpenGateways>(),
    );
    expect(
      (coordinator.menu(ProfileContactsMenuActionKind.openConfig).single
              as NavigateProfileContactsEffect)
          .intent,
      isA<OpenConfig>(),
    );
  });

  test('add profile actions distinguish seed sheet from server navigation', () {
    expect(
      coordinator.addProfile(ProfileContactsAddRowKind.newProfile).single,
      isA<ShowProfileSeedSheetEffect>(),
    );
    expect(
      (coordinator.addProfile(ProfileContactsAddRowKind.addServer).single
              as NavigateProfileContactsEffect)
          .intent,
      isA<OpenGateways>(),
    );
  });

  test('detail actions dismiss modal, select contact, then navigate', () {
    final effects = coordinator.detailAction(
      contact,
      ProfileContactDetailActionKind.openMemory,
    );

    expect(effects[0], isA<DismissProfileContactsModalEffect>());
    expect((effects[1] as SelectProfileContactEffect).contact, contact);
    expect(
      (effects[2] as NavigateProfileContactsEffect).intent,
      isA<OpenWorkspace>(),
    );
  });
}
