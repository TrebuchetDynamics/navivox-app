import 'navivox_channel.dart';
import 'navivox_profile_scope.dart';

/// Profile/server scope used by memory API requests.
///
/// Memory requests share the profile scope value object with voice-run and
/// profile-contact defaults, while keeping a memory-specific name at this seam.
typedef NavivoxMemoryScope = NavivoxProfileScope;

NavivoxMemoryScope navivoxMemoryScopeFor({
  required NavivoxProfileContact? activeProfile,
  String? serverId,
  String? profileId,
}) {
  final scope = navivoxProfileScopeFor(
    activeProfile: activeProfile,
    serverId: serverId,
    profileId: profileId,
  );
  return NavivoxMemoryScope(
    serverId: scope.serverId,
    profileId: scope.profileId,
  );
}
