import 'package:flutter/material.dart';

import '../../../core/channel/navivox_channel.dart';
import '../../../core/gateway/navivox_gateway_protocol.dart';
import '../../../core/protocol/navivox_json.dart';
import '../actions/profile_seed_coordinator.dart';

const _profileSeedCoordinator = ProfileSeedCoordinator();

class ProfileSeedSheet extends StatefulWidget {
  const ProfileSeedSheet({super.key, required this.channel});

  final NavivoxChannel channel;

  @override
  State<ProfileSeedSheet> createState() => _ProfileSeedSheetState();
}

class _ProfileSeedSheetState extends State<ProfileSeedSheet> {
  final _seedController = TextEditingController();
  final _profileIdController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _providerController = TextEditingController();
  final _modelController = TextEditingController();
  final _toolPolicyController = TextEditingController();
  final _voiceMetadataController = TextEditingController();
  final _workspacePathController = TextEditingController();

  NavivoxProfileSeedResult? _draftResult;
  bool _confirmNoWorkspace = false;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _workspacePathController.addListener(_onWorkspaceChanged);
  }

  @override
  void dispose() {
    _seedController.dispose();
    _profileIdController.dispose();
    _displayNameController.dispose();
    _instructionsController.dispose();
    _providerController.dispose();
    _modelController.dispose();
    _toolPolicyController.dispose();
    _voiceMetadataController.dispose();
    _workspacePathController
      ..removeListener(_onWorkspaceChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draftResult?.draft;
    final canApply =
        !_loading &&
        draft != null &&
        _profileSeedCoordinator.workspaceConfirmed(
          _workspaceRoots,
          _confirmNoWorkspace,
        );

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Create from seed',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Gormes drafts profile config from your text. Navivox never writes TOML or grants workspace roots directly.',
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('profile-seed-input'),
              controller: _seedController,
              decoration: const InputDecoration(
                labelText: 'Profile seed',
                hintText: 'work on mineru repo',
                border: OutlineInputBorder(),
              ),
              minLines: 1,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                key: const ValueKey('profile-seed-draft-button'),
                onPressed: _loading ? null : _generateDraft,
                icon: _loading
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: const Text('Generate draft'),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (draft != null) ...[
              const SizedBox(height: 16),
              _DraftSummary(draft: draft),
              const SizedBox(height: 12),
              TextField(
                controller: _profileIdController,
                decoration: const InputDecoration(
                  labelText: 'Profile ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _instructionsController,
                decoration: const InputDecoration(
                  labelText: 'Instructions',
                  border: OutlineInputBorder(),
                ),
                minLines: 3,
                maxLines: 6,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _providerController,
                      decoration: const InputDecoration(
                        labelText: 'Provider',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _modelController,
                      decoration: const InputDecoration(
                        labelText: 'Model',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _toolPolicyController,
                decoration: const InputDecoration(
                  labelText: 'Tool policy',
                  border: OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 5,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _voiceMetadataController,
                decoration: const InputDecoration(
                  labelText: 'Voice metadata',
                  border: OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              Text(
                'Workspace suggestions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _WorkspaceSuggestions(draft: draft),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('profile-seed-workspace-path'),
                controller: _workspacePathController,
                decoration: const InputDecoration(
                  labelText: 'Workspace root path',
                  hintText: '/absolute/path/to/workspace',
                  border: OutlineInputBorder(),
                  helperText:
                      'Only paths you type here are sent to Gormes on apply.',
                ),
              ),
              CheckboxListTile(
                key: const ValueKey('profile-seed-no-workspace-confirmation'),
                value: _confirmNoWorkspace,
                onChanged: (value) => setState(() {
                  _confirmNoWorkspace = value ?? false;
                }),
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Continue without workspace roots'),
                subtitle: const Text(
                  'I understand suggested workspaces are not granted unless I type a path.',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const ValueKey('profile-seed-apply-button'),
                onPressed: canApply ? _applyDraft : null,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Apply through Gormes'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<String> get _workspaceRoots => _profileSeedCoordinator
      .parseWorkspaceRoots(_workspacePathController.text);

  void _onWorkspaceChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _generateDraft() async {
    final plan = _profileSeedCoordinator.planDraft(_seedController.text);
    switch (plan) {
      case ShowProfileSeedDraftErrorPlan(:final message):
        setState(() => _error = message);
        return;
      case RequestProfileSeedDraftPlan(:final request):
        await _requestDraft(request);
    }
  }

  Future<void> _requestDraft(ProfileSeedDraftRequest request) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.channel.profileSeed(seed: request.seed);
      if (!mounted) return;
      setState(() {
        _draftResult = result;
        _applyProfileSeedEffect(
          _profileSeedCoordinator.afterDraftResult(result),
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _applyProfileSeedEffect(_profileSeedCoordinator.draftFailed());
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _applyDraft() async {
    final plan = _profileSeedCoordinator.planApply(
      seedText: _seedController.text,
      workspaceRootsText: _workspacePathController.text,
      confirmNoWorkspace: _confirmNoWorkspace,
    );
    switch (plan) {
      case BlockedProfileSeedApplyPlan():
        return;
      case RequestProfileSeedApplyPlan(:final request):
        await _requestApply(request);
    }
  }

  Future<void> _requestApply(ProfileSeedApplyRequest request) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.channel.profileSeed(
        seed: request.seed,
        apply: true,
        workspaceRoots: request.workspaceRoots,
      );
      if (!mounted) return;
      _applyProfileSeedEffect(_profileSeedCoordinator.applySucceeded());
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _applyProfileSeedEffect(_profileSeedCoordinator.applyFailed());
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyProfileSeedEffect(ProfileSeedEffect effect) {
    switch (effect) {
      case PopulateProfileSeedDraftEffect(:final fields):
        _profileIdController.text = fields.profileId;
        _displayNameController.text = fields.displayName;
        _instructionsController.text = fields.instructions;
        _providerController.text = fields.provider;
        _modelController.text = fields.model;
        _toolPolicyController.text = fields.toolPolicy;
        _voiceMetadataController.text = fields.voiceMetadata;
      case ShowProfileSeedErrorEffect(:final message):
        _error = message;
      case CloseProfileSeedSheetEffect():
        Navigator.of(context).pop();
    }
  }
}

class _DraftSummary extends StatelessWidget {
  const _DraftSummary({required this.draft});

  final Map<String, Object?> draft;

  @override
  Widget build(BuildContext context) {
    final providerState = navivoxMapFieldFromJson(
      draft,
      'provider_model_state',
    );
    final generationSource = navivoxStringFieldFromJson(
      draft,
      'generation_source',
    );
    final evidence = navivoxStringListFieldFromJson(draft, 'evidence');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('generation_source=$generationSource'),
            Text(
              'Provider status: ${navivoxStringFieldFromJson(providerState, 'status')}',
            ),
            if (evidence.isNotEmpty) Text('Evidence: ${evidence.join(', ')}'),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceSuggestions extends StatelessWidget {
  const _WorkspaceSuggestions({required this.draft});

  final Map<String, Object?> draft;

  @override
  Widget build(BuildContext context) {
    final suggestions =
        navivoxListFieldFromJson(draft, 'workspace_root_suggestions')
            .whereType<Map>()
            .map((item) => Map<String, Object?>.from(item))
            .toList(growable: false);
    if (suggestions.isEmpty) {
      return const Text('No workspace suggestions returned by Gormes.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final suggestion in suggestions)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.folder_open),
            title: Text(navivoxStringFieldFromJson(suggestion, 'label')),
            subtitle: Text(
              '${navivoxStringFieldFromJson(suggestion, 'purpose')} (${_boolField(suggestion, 'requires_confirmation') ? 'requires confirmation' : 'informational'})',
            ),
          ),
      ],
    );
  }
}

bool _boolField(Map<String, Object?> json, String key) {
  return navivoxStrictBoolFromJson(json[key]);
}
