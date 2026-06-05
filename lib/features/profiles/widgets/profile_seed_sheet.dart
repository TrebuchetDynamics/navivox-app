import 'package:flutter/material.dart';

import '../../../core/channel/navivox_channel.dart';
import '../../../core/gateway/navivox_gateway_protocol.dart';
import '../actions/profile_seed_coordinator.dart';
import '../presentation/profile_seed_presentation.dart';

const _profileSeedCoordinator = ProfileSeedCoordinator();
const _profileSeedPresentation = ProfileSeedPresentation();

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
              _profileSeedPresentation.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(_profileSeedPresentation.instructions),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('profile-seed-input'),
              controller: _seedController,
              decoration: InputDecoration(
                labelText: _profileSeedPresentation.seedFieldLabel,
                hintText: _profileSeedPresentation.seedFieldHint,
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
                label: Text(_profileSeedPresentation.generateDraftLabel),
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
                decoration: InputDecoration(
                  labelText: _profileSeedPresentation.profileIdFieldLabel,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _displayNameController,
                decoration: InputDecoration(
                  labelText: _profileSeedPresentation.displayNameFieldLabel,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _instructionsController,
                decoration: InputDecoration(
                  labelText: _profileSeedPresentation.instructionsFieldLabel,
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
                      decoration: InputDecoration(
                        labelText: _profileSeedPresentation.providerFieldLabel,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _modelController,
                      decoration: InputDecoration(
                        labelText: _profileSeedPresentation.modelFieldLabel,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _toolPolicyController,
                decoration: InputDecoration(
                  labelText: _profileSeedPresentation.toolPolicyFieldLabel,
                  border: OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 5,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _voiceMetadataController,
                decoration: InputDecoration(
                  labelText: _profileSeedPresentation.voiceMetadataFieldLabel,
                  border: OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              Text(
                _profileSeedPresentation.workspaceSuggestionsTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _WorkspaceSuggestions(draft: draft),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('profile-seed-workspace-path'),
                controller: _workspacePathController,
                decoration: InputDecoration(
                  labelText: _profileSeedPresentation.workspaceRootFieldLabel,
                  hintText: _profileSeedPresentation.workspaceRootFieldHint,
                  border: OutlineInputBorder(),
                  helperText: _profileSeedPresentation.workspaceRootFieldHelper,
                ),
              ),
              CheckboxListTile(
                key: const ValueKey('profile-seed-no-workspace-confirmation'),
                value: _confirmNoWorkspace,
                onChanged: (value) => setState(() {
                  _confirmNoWorkspace = value ?? false;
                }),
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  _profileSeedPresentation.noWorkspaceConfirmationTitle,
                ),
                subtitle: Text(
                  _profileSeedPresentation.noWorkspaceConfirmationSubtitle,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const ValueKey('profile-seed-apply-button'),
                onPressed: canApply ? _applyDraft : null,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(_profileSeedPresentation.applyLabel),
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
    final presentation = _profileSeedPresentation.draftSummary(draft);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(presentation.generationSourceLine),
            Text(presentation.providerStatusLine),
            if (presentation.evidenceLine != null)
              Text(presentation.evidenceLine!),
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
    final suggestions = _profileSeedPresentation.workspaceSuggestions(draft);
    if (suggestions.isEmpty) {
      return Text(_profileSeedPresentation.emptyWorkspaceSuggestions);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final suggestion in suggestions)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.folder_open),
            title: Text(suggestion.label),
            subtitle: Text(suggestion.subtitle),
          ),
      ],
    );
  }
}
