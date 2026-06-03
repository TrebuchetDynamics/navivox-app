import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/gateway/navivox_gateway_protocol.dart';
import 'package:navivox/features/profiles/actions/profile_seed_coordinator.dart';

void main() {
  const coordinator = ProfileSeedCoordinator();

  test('draft plan rejects blank seed and trims valid seed', () {
    final blank = coordinator.planDraft('   ');
    expect(blank, isA<ShowProfileSeedDraftErrorPlan>());
    expect(
      (blank as ShowProfileSeedDraftErrorPlan).message,
      'Enter a profile seed first.',
    );

    final valid = coordinator.planDraft(' work on mineru repo ');
    expect(valid, isA<RequestProfileSeedDraftPlan>());
    expect(
      (valid as RequestProfileSeedDraftPlan).request.seed,
      'work on mineru repo',
    );
  });

  test(
    'apply plan requires explicit workspace roots or no-workspace confirmation',
    () {
      final blocked = coordinator.planApply(
        seedText: 'work on mineru repo',
        workspaceRootsText: '   ',
        confirmNoWorkspace: false,
      );
      expect(blocked, isA<BlockedProfileSeedApplyPlan>());

      final withWorkspace = coordinator.planApply(
        seedText: ' work on mineru repo ',
        workspaceRootsText: ' /repo/mineru, \n /repo/navivox ',
        confirmNoWorkspace: false,
      );
      expect(withWorkspace, isA<RequestProfileSeedApplyPlan>());
      final request = (withWorkspace as RequestProfileSeedApplyPlan).request;
      expect(request.seed, 'work on mineru repo');
      expect(request.workspaceRoots, ['/repo/mineru', '/repo/navivox']);

      final noWorkspace = coordinator.planApply(
        seedText: 'work on mineru repo',
        workspaceRootsText: '   ',
        confirmNoWorkspace: true,
      );
      expect(noWorkspace, isA<RequestProfileSeedApplyPlan>());
      expect(
        (noWorkspace as RequestProfileSeedApplyPlan).request.workspaceRoots,
        isEmpty,
      );
    },
  );

  test('draft result extracts editable field presentation', () {
    final effect = coordinator.afterDraftResult(
      const NavivoxProfileSeedResult(
        action: 'profile_seed_draft',
        status: 'draft',
        applied: false,
        profileId: '',
        root: '',
        workspaceCount: 0,
        draft: {
          'profile_id': 'work-mineru-repo',
          'display_name': 'Work Mineru Repo',
          'instructions': 'Help with Mineru.',
          'provider_model_state': {'provider': 'openai', 'model': 'gpt-4.1'},
          'tool_policy': {
            'mode': 'safe',
            'allowed': ['read', 'search'],
            'requires_approval': ['write_files'],
          },
          'voice_profile_metadata': {
            'status': 'draft',
            'languages': ['en', 'ja'],
          },
        },
        contact: {},
      ),
    );

    expect(effect, isA<PopulateProfileSeedDraftEffect>());
    final fields = (effect as PopulateProfileSeedDraftEffect).fields;
    expect(fields.profileId, 'work-mineru-repo');
    expect(fields.displayName, 'Work Mineru Repo');
    expect(fields.instructions, 'Help with Mineru.');
    expect(fields.provider, 'openai');
    expect(fields.model, 'gpt-4.1');
    expect(fields.toolPolicy, contains('mode: safe'));
    expect(fields.toolPolicy, contains('allowed: read, search'));
    expect(fields.toolPolicy, contains('requires_approval: write_files'));
    expect(fields.voiceMetadata, contains('status: draft'));
    expect(fields.voiceMetadata, contains('languages: en, ja'));
  });

  test('failure and success outcomes map to typed effects', () {
    expect(coordinator.draftFailed(), isA<ShowProfileSeedErrorEffect>());
    expect(
      (coordinator.applyFailed() as ShowProfileSeedErrorEffect).message,
      'Gormes profile seed apply failed.',
    );
    expect(coordinator.applySucceeded(), isA<CloseProfileSeedSheetEffect>());
  });
}
