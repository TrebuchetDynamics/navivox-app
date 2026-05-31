import '../../core/channel/navivox_channel.dart';
import 'profile_contact_labels.dart';

const _profileContactAvatarColorSlots = 18;

/// Stable avatar contract shared by profile-contact screens and widgets.
class ProfileContactAvatarPresentation {
  const ProfileContactAvatarPresentation(this.contact);

  final NavivoxProfileContact contact;

  String get initial {
    final runes = _label.runes;
    if (runes.isEmpty) return '?';
    return String.fromCharCode(runes.first).toUpperCase();
  }

  int get colorIndex =>
      contact.avatarSeed.codeUnits.fold<int>(0, (sum, unit) => sum + unit) %
      _profileContactAvatarColorSlots;

  String get semanticLabel => '$_label profile avatar';

  String get _label => profileContactIdentityLabel(contact, fallback: 'profile');
}
