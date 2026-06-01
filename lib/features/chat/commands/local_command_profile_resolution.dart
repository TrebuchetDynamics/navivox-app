import '../../../core/channel/navivox_channel.dart';
import 'local_command_profile_matcher.dart';

/// Pure profile-command candidate classification before policy gates are applied.
///
/// This keeps the hidden ordering explicit: first decide whether a local command
/// body names a Profile contact, then let settings such as voice profile
/// switching decide whether that matched profile command may execute.
enum LocalCommandProfileResolutionKind {
  unmatchable,
  noMatch,
  single,
  ambiguous,
}

class LocalCommandProfileResolution {
  const LocalCommandProfileResolution._({required this.kind, this.target});

  const LocalCommandProfileResolution.unmatchable()
    : this._(kind: LocalCommandProfileResolutionKind.unmatchable);

  const LocalCommandProfileResolution.noMatch()
    : this._(kind: LocalCommandProfileResolutionKind.noMatch);

  const LocalCommandProfileResolution.single(NavivoxProfileContact target)
    : this._(kind: LocalCommandProfileResolutionKind.single, target: target);

  const LocalCommandProfileResolution.ambiguous()
    : this._(kind: LocalCommandProfileResolutionKind.ambiguous);

  final LocalCommandProfileResolutionKind kind;
  final NavivoxProfileContact? target;
}

class LocalCommandProfileResolver {
  const LocalCommandProfileResolver();

  LocalCommandProfileResolution resolve({
    required String normalized,
    required Iterable<NavivoxProfileContact> contacts,
    required String Function(String value) normalize,
  }) {
    if (normalized.isEmpty) {
      return const LocalCommandProfileResolution.unmatchable();
    }

    final matches = matchingLocalCommandContacts(
      normalized: normalized,
      contacts: contacts,
      normalize: normalize,
    );
    if (matches.isEmpty) {
      return const LocalCommandProfileResolution.noMatch();
    }
    if (matches.length == 1) {
      return LocalCommandProfileResolution.single(matches.single);
    }
    return const LocalCommandProfileResolution.ambiguous();
  }
}
