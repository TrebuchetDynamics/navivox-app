import '../../../core/channel/navivox_channel.dart';
import 'local_command_body_parser.dart';
import 'local_command_builtins.dart';
import 'local_command_profile_matcher.dart';
import 'local_command_text.dart';

enum LocalCommandAction {
  none,
  enterCommandMode,
  cancel,
  stop,
  openSettings,
  showMessage,
  switchProfile,
  disambiguateProfile,
  profileSwitchingDisabled,
  unknown,
}

class LocalCommandIntent {
  const LocalCommandIntent._({
    required this.action,
    this.body,
    this.message,
    this.target,
  });

  const LocalCommandIntent.none() : this._(action: LocalCommandAction.none);

  const LocalCommandIntent.enterCommandMode()
    : this._(action: LocalCommandAction.enterCommandMode);

  const LocalCommandIntent.cancel()
    : this._(
        action: LocalCommandAction.cancel,
        message: 'Cancel requested. Started side effects may still exist.',
      );

  const LocalCommandIntent.stop()
    : this._(
        action: LocalCommandAction.stop,
        message: 'Stop requested. Started side effects may still exist.',
      );

  const LocalCommandIntent.openSettings()
    : this._(action: LocalCommandAction.openSettings);

  LocalCommandIntent.help(String commandWord)
    : this._(
        action: LocalCommandAction.showMessage,
        message: localCommandHelpMessage(commandWord),
      );

  const LocalCommandIntent.profileSwitchingDisabled()
    : this._(
        action: LocalCommandAction.profileSwitchingDisabled,
        message: 'Voice profile switching is disabled.',
      );

  LocalCommandIntent.switchProfile(NavivoxProfileContact target)
    : this._(
        action: LocalCommandAction.switchProfile,
        target: target,
        message: 'Switched to ${target.displayName}.',
      );

  LocalCommandIntent.disambiguateProfile(String body)
    : this._(
        action: LocalCommandAction.disambiguateProfile,
        body: body,
        message: 'Choose one profile named ${body.trim()}.',
      );

  LocalCommandIntent.unknown(String body)
    : this._(
        action: LocalCommandAction.unknown,
        body: body,
        message: 'Voice command not recognized: ${body.trim()}.',
      );

  final LocalCommandAction action;
  final String? body;
  final String? message;
  final NavivoxProfileContact? target;

  bool get consumesInput => action != LocalCommandAction.none;
}

class _ProfileCommandCandidate {
  const _ProfileCommandCandidate({
    required this.body,
    required this.normalized,
  });

  final String body;
  final String normalized;

  bool get hasMatchableText => normalized.isNotEmpty;
}

class LocalCommandResolver {
  const LocalCommandResolver();

  final LocalCommandBodyParser _commandBodyParser =
      const LocalCommandBodyParser();

  LocalCommandIntent resolve({
    required String raw,
    required String commandWord,
    required bool commandMode,
    required bool fromVoice,
    required bool profileSwitchingEnabled,
    required List<NavivoxProfileContact> contacts,
  }) {
    final body = commandBody(
      raw,
      commandWord: commandWord,
      commandMode: commandMode,
      fromVoice: fromVoice,
    );
    if (body == null) return const LocalCommandIntent.none();
    if (body.isEmpty) return const LocalCommandIntent.enterCommandMode();

    final normalized = normalize(body);
    final builtin = localCommandBuiltinFromNormalizedBody(normalized);
    if (builtin != null) {
      return _resolveBuiltinCommand(builtin, commandWord: commandWord);
    }
    return _resolveProfileCommand(
      _ProfileCommandCandidate(body: body, normalized: normalized),
      profileSwitchingEnabled: profileSwitchingEnabled,
      contacts: contacts,
    );
  }

  String? commandBody(
    String raw, {
    required String commandWord,
    required bool commandMode,
    required bool fromVoice,
  }) {
    return _commandBodyParser.commandBody(
      raw,
      commandWord: commandWord,
      commandMode: commandMode,
      fromVoice: fromVoice,
    );
  }

  LocalCommandIntent _resolveBuiltinCommand(
    LocalCommandBuiltin command, {
    required String commandWord,
  }) {
    return switch (command) {
      LocalCommandBuiltin.cancel => const LocalCommandIntent.cancel(),
      LocalCommandBuiltin.stop => const LocalCommandIntent.stop(),
      LocalCommandBuiltin.settings => const LocalCommandIntent.openSettings(),
      LocalCommandBuiltin.help => LocalCommandIntent.help(
        commandWord.trim().toLowerCase(),
      ),
    };
  }

  LocalCommandIntent _resolveProfileCommand(
    _ProfileCommandCandidate candidate, {
    required bool profileSwitchingEnabled,
    required List<NavivoxProfileContact> contacts,
  }) {
    if (!candidate.hasMatchableText) {
      return LocalCommandIntent.unknown(candidate.body);
    }
    if (!profileSwitchingEnabled) {
      return const LocalCommandIntent.profileSwitchingDisabled();
    }

    final matches = _matchingProfileCommandContacts(
      normalized: candidate.normalized,
      contacts: contacts,
    );
    if (matches.length == 1) {
      return LocalCommandIntent.switchProfile(matches.single);
    }
    if (matches.length > 1) {
      return LocalCommandIntent.disambiguateProfile(candidate.body);
    }
    return LocalCommandIntent.unknown(candidate.body);
  }

  List<NavivoxProfileContact> _matchingProfileCommandContacts({
    required String normalized,
    required List<NavivoxProfileContact> contacts,
  }) {
    return matchingLocalCommandContacts(
      normalized: normalized,
      contacts: contacts,
      normalize: normalize,
    );
  }

  String normalize(String value) {
    return normalizeLocalCommandText(value);
  }
}
