import '../../../core/gateway/navivox_gateway_protocol.dart';
import '../../../core/protocol/navivox_json.dart';

final class ProfileSeedCoordinator {
  const ProfileSeedCoordinator();

  ProfileSeedDraftPlan planDraft(String seedText) {
    final seed = seedText.trim();
    if (seed.isEmpty) {
      return const ProfileSeedDraftPlan.showError(
        'Enter a profile seed first.',
      );
    }
    return ProfileSeedDraftPlan.request(ProfileSeedDraftRequest(seed: seed));
  }

  ProfileSeedApplyPlan planApply({
    required String seedText,
    required String workspaceRootsText,
    required bool confirmNoWorkspace,
  }) {
    final seed = seedText.trim();
    final workspaceRoots = parseWorkspaceRoots(workspaceRootsText);
    if (seed.isEmpty ||
        !workspaceConfirmed(workspaceRoots, confirmNoWorkspace)) {
      return const ProfileSeedApplyPlan.blocked();
    }
    return ProfileSeedApplyPlan.request(
      ProfileSeedApplyRequest(seed: seed, workspaceRoots: workspaceRoots),
    );
  }

  List<String> parseWorkspaceRoots(String value) {
    return navivoxTrimmedStringList(value.split(RegExp(r'[\n,]')));
  }

  bool workspaceConfirmed(
    List<String> workspaceRoots,
    bool confirmNoWorkspace,
  ) {
    return workspaceRoots.isNotEmpty || confirmNoWorkspace;
  }

  ProfileSeedDraftFields fieldsForDraft(Map<String, Object?> draft) {
    final providerState = navivoxMapFieldFromJson(
      draft,
      'provider_model_state',
    );
    return ProfileSeedDraftFields(
      profileId: navivoxStringFieldFromJson(draft, 'profile_id'),
      displayName: navivoxStringFieldFromJson(draft, 'display_name'),
      instructions: navivoxStringFieldFromJson(draft, 'instructions'),
      provider: navivoxStringFieldFromJson(providerState, 'provider'),
      model: navivoxStringFieldFromJson(providerState, 'model'),
      toolPolicy: toolPolicyText(navivoxMapFieldFromJson(draft, 'tool_policy')),
      voiceMetadata: keyValueText(
        navivoxMapFieldFromJson(draft, 'voice_profile_metadata'),
      ),
    );
  }

  ProfileSeedEffect afterDraftResult(NavivoxProfileSeedResult result) {
    return ProfileSeedEffect.populateDraft(fieldsForDraft(result.draft));
  }

  ProfileSeedEffect draftFailed() {
    return const ProfileSeedEffect.showError(
      'Gormes profile seed draft failed.',
    );
  }

  ProfileSeedEffect applyFailed() {
    return const ProfileSeedEffect.showError(
      'Gormes profile seed apply failed.',
    );
  }

  ProfileSeedEffect applySucceeded() {
    return const ProfileSeedEffect.closeSheet();
  }

  String toolPolicyText(Map<String, Object?> toolPolicy) {
    final lines = <String>[];
    final mode = navivoxStringFieldFromJson(toolPolicy, 'mode');
    if (mode.isNotEmpty) lines.add('mode: $mode');
    final allowed = navivoxStringListFieldFromJson(toolPolicy, 'allowed');
    if (allowed.isNotEmpty) lines.add('allowed: ${allowed.join(', ')}');
    final requiresApproval = navivoxStringListFieldFromJson(
      toolPolicy,
      'requires_approval',
    );
    if (requiresApproval.isNotEmpty) {
      lines.add('requires_approval: ${requiresApproval.join(', ')}');
    }
    return lines.join('\n');
  }

  String keyValueText(Map<String, Object?> values) {
    final lines = <String>[];
    for (final entry in values.entries) {
      final value = entry.value;
      if (value == null) continue;
      if (value is List) {
        lines.add('${entry.key}: ${value.join(', ')}');
      } else {
        lines.add('${entry.key}: $value');
      }
    }
    return lines.join('\n');
  }
}

sealed class ProfileSeedDraftPlan {
  const ProfileSeedDraftPlan._();

  const factory ProfileSeedDraftPlan.request(ProfileSeedDraftRequest request) =
      RequestProfileSeedDraftPlan;
  const factory ProfileSeedDraftPlan.showError(String message) =
      ShowProfileSeedDraftErrorPlan;
}

final class RequestProfileSeedDraftPlan extends ProfileSeedDraftPlan {
  const RequestProfileSeedDraftPlan(this.request) : super._();

  final ProfileSeedDraftRequest request;
}

final class ShowProfileSeedDraftErrorPlan extends ProfileSeedDraftPlan {
  const ShowProfileSeedDraftErrorPlan(this.message) : super._();

  final String message;
}

sealed class ProfileSeedApplyPlan {
  const ProfileSeedApplyPlan._();

  const factory ProfileSeedApplyPlan.request(ProfileSeedApplyRequest request) =
      RequestProfileSeedApplyPlan;
  const factory ProfileSeedApplyPlan.blocked() = BlockedProfileSeedApplyPlan;
}

final class RequestProfileSeedApplyPlan extends ProfileSeedApplyPlan {
  const RequestProfileSeedApplyPlan(this.request) : super._();

  final ProfileSeedApplyRequest request;
}

final class BlockedProfileSeedApplyPlan extends ProfileSeedApplyPlan {
  const BlockedProfileSeedApplyPlan() : super._();
}

final class ProfileSeedDraftRequest {
  const ProfileSeedDraftRequest({required this.seed});

  final String seed;
}

final class ProfileSeedApplyRequest {
  const ProfileSeedApplyRequest({
    required this.seed,
    required this.workspaceRoots,
  });

  final String seed;
  final List<String> workspaceRoots;
}

final class ProfileSeedDraftFields {
  const ProfileSeedDraftFields({
    required this.profileId,
    required this.displayName,
    required this.instructions,
    required this.provider,
    required this.model,
    required this.toolPolicy,
    required this.voiceMetadata,
  });

  final String profileId;
  final String displayName;
  final String instructions;
  final String provider;
  final String model;
  final String toolPolicy;
  final String voiceMetadata;
}

sealed class ProfileSeedEffect {
  const ProfileSeedEffect._();

  const factory ProfileSeedEffect.populateDraft(ProfileSeedDraftFields fields) =
      PopulateProfileSeedDraftEffect;
  const factory ProfileSeedEffect.showError(String message) =
      ShowProfileSeedErrorEffect;
  const factory ProfileSeedEffect.closeSheet() = CloseProfileSeedSheetEffect;
}

final class PopulateProfileSeedDraftEffect extends ProfileSeedEffect {
  const PopulateProfileSeedDraftEffect(this.fields) : super._();

  final ProfileSeedDraftFields fields;
}

final class ShowProfileSeedErrorEffect extends ProfileSeedEffect {
  const ShowProfileSeedErrorEffect(this.message) : super._();

  final String message;
}

final class CloseProfileSeedSheetEffect extends ProfileSeedEffect {
  const CloseProfileSeedSheetEffect() : super._();
}
