import 'package:flutter/material.dart';

import '../../../core/channel/navivox_channel.dart';
import '../../../core/gateway/navivox_gateway_protocol.dart';
import '../actions/profile_voice_profile_coordinator.dart';
import '../presentation/profile_voice_profile_presentation.dart';

const _profileVoiceCoordinator = ProfileVoiceProfileCoordinator();
const _profileVoicePresentation = ProfileVoiceProfilePresentation();

class ProfileVoiceProfileCard extends StatefulWidget {
  const ProfileVoiceProfileCard({super.key, required this.channel});

  final NavivoxChannel channel;

  @override
  State<ProfileVoiceProfileCard> createState() =>
      _ProfileVoiceProfileCardState();
}

class _ProfileVoiceProfileCardState extends State<ProfileVoiceProfileCard> {
  final _sttProviderController = TextEditingController();
  final _ttsProviderController = TextEditingController();
  final _voiceIdController = TextEditingController();
  final _languagePolicyController = TextEditingController();
  final _fallbackVoiceController = TextEditingController();
  final _sttCredentialController = TextEditingController();
  final _ttsCredentialController = TextEditingController();

  NavivoxVoiceProfilesResponse? _profiles;
  NavivoxVoiceProfileValidationResponse? _validation;
  NavivoxRunRecordSnapshot? _runRecord;
  String? _statusMessage;
  String? _error;
  bool _loading = false;
  bool _editing = false;
  String? _loadedProfileKey;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  @override
  void didUpdateWidget(ProfileVoiceProfileCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final key = widget.channel.state.activeProfileContact?.key;
    if (oldWidget.channel != widget.channel || key != _loadedProfileKey) {
      _loadProfiles();
    }
  }

  @override
  void dispose() {
    _sttProviderController.dispose();
    _ttsProviderController.dispose();
    _voiceIdController.dispose();
    _languagePolicyController.dispose();
    _fallbackVoiceController.dispose();
    _sttCredentialController.dispose();
    _ttsCredentialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.channel.state.activeProfileContact;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _profileVoicePresentation.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(_profileVoicePresentation.textFallbackNotice),
            if (active == null) ...[
              const SizedBox(height: 8),
              Text(_profileVoicePresentation.selectProfileMessage),
            ] else if (_loading) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ] else if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ] else ...[
              const SizedBox(height: 12),
              _buildProfileContent(context, active),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    NavivoxProfileContact active,
  ) {
    final response = _profiles;
    final view = _profileVoiceCoordinator.activeVoiceProfile(
      profiles: response,
      activeProfile: active,
    );
    if (response == null || view == null) {
      return Text(_profileVoicePresentation.noProfileMessage);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_profileVoicePresentation.profileLine(view)),
        Text(
          _profileVoicePresentation.availableSttLine(response.providerMatrix),
        ),
        Text(
          _profileVoicePresentation.availableTtsLine(response.providerMatrix),
        ),
        const SizedBox(height: 8),
        if (_editing)
          _VoiceProfileEditor(
            sttProviderController: _sttProviderController,
            ttsProviderController: _ttsProviderController,
            voiceIdController: _voiceIdController,
            languagePolicyController: _languagePolicyController,
            fallbackVoiceController: _fallbackVoiceController,
            sttCredentialController: _sttCredentialController,
            ttsCredentialController: _ttsCredentialController,
            validationErrors: _validation?.errors ?? const [],
            onApply: () => _validateAndApply(view),
            onCancel: () => setState(() => _editing = false),
          )
        else ...[
          Text(_profileVoicePresentation.sttProviderLine(view.voiceProfile)),
          Text(_profileVoicePresentation.ttsProviderLine(view.voiceProfile)),
          Text(_profileVoicePresentation.voiceIdLine(view.voiceProfile)),
          Text(_profileVoicePresentation.languagePolicyLine(view.voiceProfile)),
          Text(_profileVoicePresentation.fallbackVoiceLine(view.voiceProfile)),
          const SizedBox(height: 8),
          Text(
            _profileVoicePresentation.sttCredentialLine(
              view.credentialStatusRefs['stt'],
            ),
          ),
          Text(
            _profileVoicePresentation.ttsCredentialLine(
              view.credentialStatusRefs['tts'],
            ),
          ),
          for (final error in view.errors)
            Text(_profileVoicePresentation.validationErrorLine(error)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                key: const ValueKey('voice-profile-edit'),
                onPressed: () => _beginEditing(view),
                icon: const Icon(Icons.edit_outlined),
                label: Text(_profileVoicePresentation.editActionLabel),
              ),
              OutlinedButton.icon(
                key: const ValueKey('voice-profile-load-evidence'),
                onPressed: _loadRunRecordEvidence,
                icon: const Icon(Icons.history),
                label: Text(_profileVoicePresentation.loadEvidenceActionLabel),
              ),
            ],
          ),
        ],
        if (_statusMessage != null) ...[
          const SizedBox(height: 8),
          Text(_statusMessage!),
        ],
        if (_runRecord != null) ...[
          const SizedBox(height: 8),
          _VoiceRunEvidence(record: _runRecord!),
        ],
      ],
    );
  }

  Future<void> _loadProfiles() async {
    final channel = widget.channel;
    final key = channel.state.activeProfileContact?.key;
    setState(() {
      _loadedProfileKey = key;
      _loading = key != null;
      _error = null;
      _validation = null;
      _runRecord = null;
      _statusMessage = null;
      _editing = false;
    });
    if (key == null) return;
    try {
      final profiles = await channel.voiceProfiles();
      if (!mounted || widget.channel != channel) return;
      setState(() {
        _profiles = profiles;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = _profileVoicePresentation.unavailableMessage;
        _loading = false;
      });
    }
  }

  void _beginEditing(NavivoxVoiceProfileView view) {
    final fields = _profileVoiceCoordinator.beginEditing(view);
    _sttProviderController.text = fields.sttProvider;
    _ttsProviderController.text = fields.ttsProvider;
    _voiceIdController.text = fields.voiceId;
    _languagePolicyController.text = fields.languagePolicy;
    _fallbackVoiceController.text = fields.fallbackVoice;
    _sttCredentialController.text = fields.sttCredential;
    _ttsCredentialController.text = fields.ttsCredential;
    setState(() {
      _editing = true;
      _validation = null;
      _statusMessage = null;
    });
  }

  Future<void> _validateAndApply(NavivoxVoiceProfileView view) async {
    final request = _profileVoiceCoordinator.applyRequest(
      profileId: view.profileId,
      sttProvider: _sttProviderController.text,
      ttsProvider: _ttsProviderController.text,
      voiceId: _voiceIdController.text,
      languagePolicy: _languagePolicyController.text,
      fallbackVoice: _fallbackVoiceController.text,
      sttCredential: _sttCredentialController.text,
      ttsCredential: _ttsCredentialController.text,
    );
    final validation = await widget.channel.validateVoiceProfile(
      profileId: request.profileId,
      voiceProfile: request.voiceProfile,
    );
    if (!mounted) return;
    switch (_profileVoiceCoordinator.afterValidation(validation)) {
      case ShowProfileVoiceValidationEffect(:final validation):
        setState(() => _validation = validation);
        return;
      case ContinueProfileVoiceApplyEffect():
        setState(() => _validation = validation);
      case ProfileVoiceAppliedEffect():
        break;
    }

    for (final field in request.configSets) {
      widget.channel.sendConfigSet(field: field.field, value: field.value);
    }
    for (final secret in request.secretSets) {
      widget.channel.sendConfigSecretSet(
        name: secret.name,
        secret: secret.secret,
      );
    }
    _applyProfileVoiceEffect(_profileVoiceCoordinator.applySucceeded());
  }

  Future<void> _loadRunRecordEvidence() async {
    final plan = _profileVoiceCoordinator.evidencePlan(
      widget.channel.state.latestVoiceRun,
    );
    switch (plan) {
      case ShowProfileVoiceEvidenceStatusPlan(:final message):
        setState(() => _statusMessage = message);
        return;
      case RequestProfileVoiceEvidencePlan(:final id):
        final record = await widget.channel.runRecord(id);
        if (!mounted) return;
        setState(() {
          _runRecord = record;
          _statusMessage = null;
        });
    }
  }

  void _applyProfileVoiceEffect(ProfileVoiceEffect effect) {
    switch (effect) {
      case ProfileVoiceAppliedEffect(:final message):
        _sttCredentialController.clear();
        _ttsCredentialController.clear();
        setState(() {
          _editing = false;
          _statusMessage = message;
        });
      case ShowProfileVoiceValidationEffect(:final validation):
        setState(() => _validation = validation);
      case ContinueProfileVoiceApplyEffect():
        break;
    }
  }
}

class _VoiceProfileEditor extends StatelessWidget {
  const _VoiceProfileEditor({
    required this.sttProviderController,
    required this.ttsProviderController,
    required this.voiceIdController,
    required this.languagePolicyController,
    required this.fallbackVoiceController,
    required this.sttCredentialController,
    required this.ttsCredentialController,
    required this.validationErrors,
    required this.onApply,
    required this.onCancel,
  });

  final TextEditingController sttProviderController;
  final TextEditingController ttsProviderController;
  final TextEditingController voiceIdController;
  final TextEditingController languagePolicyController;
  final TextEditingController fallbackVoiceController;
  final TextEditingController sttCredentialController;
  final TextEditingController ttsCredentialController;
  final List<NavivoxVoiceProfileFieldError> validationErrors;
  final VoidCallback onApply;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _input('stt_provider', 'STT provider', sttProviderController),
        _input('tts_provider', 'TTS provider', ttsProviderController),
        _input('voice_id', 'Voice ID', voiceIdController),
        _input('language_policy', 'Language policy', languagePolicyController),
        _input('fallback_voice', 'Fallback voice', fallbackVoiceController),
        _input(
          'stt_credential',
          'STT credential (write-only)',
          sttCredentialController,
          obscureText: true,
        ),
        _input(
          'tts_credential',
          'TTS credential (write-only)',
          ttsCredentialController,
          obscureText: true,
        ),
        for (final error in validationErrors)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _profileVoicePresentation.validationErrorLine(error),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            FilledButton(
              key: const ValueKey('voice-profile-validate-apply'),
              onPressed: onApply,
              child: Text(_profileVoicePresentation.applyActionLabel),
            ),
            TextButton(
              onPressed: onCancel,
              child: Text(_profileVoicePresentation.cancelActionLabel),
            ),
          ],
        ),
      ],
    );
  }

  Widget _input(
    String field,
    String label,
    TextEditingController controller, {
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        key: ValueKey('voice-profile-input-$field'),
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _VoiceRunEvidence extends StatelessWidget {
  const _VoiceRunEvidence({required this.record});

  final NavivoxRunRecordSnapshot record;

  @override
  Widget build(BuildContext context) {
    final presentation = _profileVoicePresentation.evidenceFor(record);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text(presentation.serverSttLine), Text(presentation.ttsLine)],
    );
  }
}
