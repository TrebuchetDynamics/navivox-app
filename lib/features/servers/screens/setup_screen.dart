import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/channel/navivox_channel_provider.dart';
import '../../../core/protocol/navivox_endpoint_uri.dart';
import '../../../core/session/session_persistence_service.dart';
import '../../../router/navigation_intent.dart';
import '../models/connection_import.dart';
import '../pairing/pairing_handoff_flow.dart';
import '../pairing/pairing_intent.dart';
import '../pairing/pairing_intent_coordinator.dart';
import '../shared/gateway_connection_presentation.dart';
import '../setup/navivox_connect_intent_source.dart';
import '../setup/navivox_connect_intent_source_provider.dart';
import '../setup/setup_guide_presentation.dart';
import '../setup/setup_qr_import_presentation.dart';
import '../setup/setup_screen_presentation.dart';

export '../models/connection_import.dart'
    show PairingHandoffSource, SetupQrImageImport;

export '../setup/setup_qr_import_presentation.dart' show parseNavivoxQrPayload;

const _setupGuidePresentation = SetupGuidePresentation();
const _setupScreenPresentation = SetupScreenPresentation();

typedef SetupQrImageImporter = Future<SetupQrImageImport?> Function();

class SetupQrImageImportException implements Exception {
  const SetupQrImageImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({
    this.qrImageImporter,
    this.connectIntentSource,
    super.key,
  });

  final SetupQrImageImporter? qrImageImporter;
  final NavivoxConnectIntentSource? connectIntentSource;

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupHero extends StatelessWidget {
  const _SetupHero({required this.title, required this.instructions});

  final String title;
  final String instructions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.primaryContainer,
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withAlpha(48),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Icon(
            Icons.graphic_eq,
            color: colorScheme.onPrimaryContainer,
            size: 36,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            instructions,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _SetupInfoCard extends StatelessWidget {
  const _SetupInfoCard({required this.icon, required this.child});

  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: colorScheme.onSecondaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _SetupNoticeBanner extends StatelessWidget {
  const _SetupNoticeBanner({required this.notice});

  final SetupScreenNotice notice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final background = notice.isError
        ? colorScheme.errorContainer
        : colorScheme.primaryContainer;
    final foreground = notice.isError
        ? colorScheme.onErrorContainer
        : colorScheme.onPrimaryContainer;

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              notice.isError ? Icons.error_outline : Icons.check_circle_outline,
              color: foreground,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notice.message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  if (notice.recoveryMessage != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      notice.recoveryMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: foreground,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _addressController = TextEditingController(text: '127.0.0.1');
  final _portController = TextEditingController(text: '8765');
  final _tokenController = TextEditingController();
  bool _connecting = false;
  bool _showToken = false;
  bool _importingQr = false;
  String _scheme = 'http';
  String? _webSocketUrl;
  PairingHandoffFlow _handoffFlow = const PairingHandoffFlow();
  SetupScreenNotice? _notice;
  late final NavivoxConnectIntentSource _connectIntentSource;
  StreamSubscription<SetupQrImageImport>? _connectIntentSubscription;

  @override
  void initState() {
    super.initState();
    _connectIntentSource =
        widget.connectIntentSource ??
        ref.read(navivoxConnectIntentSourceProvider);
    unawaited(_startConnectIntentHandling());
    unawaited(_tryAutoReconnect());
  }

  @override
  void dispose() {
    _connectIntentSubscription?.cancel();
    _addressController.dispose();
    _portController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _tryAutoReconnect() async {
    final session = SessionPersistenceService();
    final saved = await session.loadSession();
    if (saved == null || saved.isStale) return;
    if (!saved.canAttemptReconnect) {
      if (!mounted) return;
      setState(() {
        _notice = const SetupScreenNotice.info(
          'Known gateway saved. Pair again to reconnect.',
        );
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _connecting = true;
      _notice = const SetupScreenNotice.info('Reconnecting to saved gateway…');
    });
    try {
      await ref
          .read(gatewayNavivoxChannelProvider)
          .connect(baseUrl: saved.baseUrl, webSocketUrl: saved.webSocketUrl);
      // Reconnect success: router redirect will handle navigation to chat.
    } catch (_) {
      if (mounted) {
        final stale = saved.isStale;
        setState(() {
          _notice = SetupScreenNotice.error(
            stale
                ? 'Saved session expired. Please pair again with your gateway.'
                : 'Could not reconnect to saved gateway. Pair again.',
            recoveryMessage:
                'Run `gormes navivox pair` on your host and try again.',
          );
        });
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Navivox')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 560;

            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.primaryContainer.withAlpha(
                      colorScheme.brightness == Brightness.dark ? 44 : 96,
                    ),
                    colorScheme.surface,
                    colorScheme.surface,
                  ],
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 16 : 24,
                    vertical: compact ? 20 : 32,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SetupHero(
                          title: _setupScreenPresentation.title,
                          instructions:
                              _setupScreenPresentation.pairingInstructions,
                        ),
                        const SizedBox(height: 20),
                        _SetupInfoCard(
                          icon: Icons.security,
                          child: Text(
                            _setupScreenPresentation.networkHint,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.45,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          elevation: 0,
                          child: Padding(
                            padding: EdgeInsets.all(compact ? 16 : 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Connection details',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (compact) ...[
                                  _addressField(),
                                  const SizedBox(height: 12),
                                  _portField(width: double.infinity),
                                ] else
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: _addressField()),
                                      const SizedBox(width: 12),
                                      _portField(width: 124),
                                    ],
                                  ),
                                const SizedBox(height: 12),
                                _tokenField(),
                                const SizedBox(height: 8),
                                Wrap(
                                  alignment: WrapAlignment.end,
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    TextButton.icon(
                                      key: const ValueKey(
                                        'setup-import-qr-button',
                                      ),
                                      onPressed: _connecting || _importingQr
                                          ? null
                                          : _importQrImage,
                                      icon: _importingQr
                                          ? const SizedBox.square(
                                              dimension: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(Icons.qr_code_scanner),
                                      label: Text(
                                        _setupScreenPresentation
                                            .importQrButtonLabel,
                                      ),
                                    ),
                                    TextButton.icon(
                                      key: const ValueKey(
                                        'setup-copy-fix-instructions-button',
                                      ),
                                      onPressed: () => _copySetupGuideEntry(
                                        _setupGuidePresentation.entry(
                                          SetupGuideEntryId.navivoxPairHandoff,
                                        ),
                                      ),
                                      icon: const Icon(Icons.content_copy),
                                      label: Text(
                                        _setupScreenPresentation
                                            .fixInstructionsButtonLabel,
                                      ),
                                    ),
                                    TextButton.icon(
                                      key: const ValueKey(
                                        'setup-token-visibility-button',
                                      ),
                                      onPressed: () {
                                        setState(
                                          () => _showToken = !_showToken,
                                        );
                                      },
                                      icon: Icon(
                                        _showToken
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      label: Text(
                                        _setupScreenPresentation
                                            .tokenVisibilityLabel(
                                              showToken: _showToken,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_notice != null) ...[
                                  const SizedBox(height: 12),
                                  _SetupNoticeBanner(notice: _notice!),
                                ],
                                const SizedBox(height: 16),
                                Semantics(
                                  container: true,
                                  label: _setupScreenPresentation
                                      .connectButtonLabel,
                                  hint: _setupScreenPresentation
                                      .connectButtonSemanticHint,
                                  button: true,
                                  enabled: !_connecting,
                                  onTap: _connecting
                                      ? null
                                      : _submitManualPairingHandoff,
                                  child: ExcludeSemantics(
                                    child: FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        minimumSize: const Size.fromHeight(52),
                                        textStyle: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      onPressed: _connecting
                                          ? null
                                          : _submitManualPairingHandoff,
                                      icon: _connecting
                                          ? const SizedBox.square(
                                              dimension: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(Icons.hub),
                                      label: Text(
                                        _setupScreenPresentation
                                            .connectButtonLabel,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SetupInfoCard(
                          icon: Icons.terminal,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _setupGuidePresentation.introCopy,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 12),
                              for (final entry
                                  in _setupGuidePresentation
                                      .visibleEntries) ...[
                                if (entry.id != SetupGuideEntryId.bootstrap)
                                  const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: () => _copySetupGuideEntry(entry),
                                  icon: Icon(_setupGuideIcon(entry.id)),
                                  label: Text(entry.label),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _addressField() {
    return Semantics(
      label: _setupScreenPresentation.addressFieldSemanticLabel,
      hint: _setupScreenPresentation.addressFieldSemanticHint,
      textField: true,
      child: TextField(
        controller: _addressController,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.dns_outlined),
          labelText: _setupScreenPresentation.addressFieldLabel,
        ),
        keyboardType: TextInputType.url,
        textInputAction: TextInputAction.next,
        onChanged: _handleAddressChanged,
        onSubmitted: (_) => FocusScope.of(context).nextFocus(),
      ),
    );
  }

  Widget _portField({required double width}) {
    return SizedBox(
      width: width,
      child: Semantics(
        label: _setupScreenPresentation.portFieldSemanticLabel,
        hint: _setupScreenPresentation.portFieldSemanticHint,
        textField: true,
        child: TextField(
          controller: _portController,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            prefixIcon: width > 160 ? const Icon(Icons.tag) : null,
            labelText: _setupScreenPresentation.portFieldLabel,
          ),
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: _handlePortChanged,
          onSubmitted: (_) => FocusScope.of(context).nextFocus(),
        ),
      ),
    );
  }

  Widget _tokenField() {
    return Semantics(
      label: _setupScreenPresentation.tokenFieldSemanticLabel,
      hint: _setupScreenPresentation.tokenFieldSemanticHint,
      textField: true,
      obscured: !_showToken,
      child: TextField(
        controller: _tokenController,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.key_outlined),
          labelText: _setupScreenPresentation.tokenFieldLabel,
        ),
        obscureText: !_showToken,
        textInputAction: TextInputAction.done,
        onSubmitted: _connecting ? null : (_) => _submitManualPairingHandoff(),
      ),
    );
  }

  Future<void> _importQrImage() async {
    setState(() {
      _importingQr = true;
      _notice = null;
    });
    try {
      final importer = widget.qrImageImporter ?? importNavivoxQrImage;
      final result = (await importer())?.withSource(
        PairingHandoffSource.qrImage,
      );
      if (!mounted) return;
      final notice = _setupScreenPresentation.qrImportNotice(result);
      if (result == null || !result.hasValues) {
        setState(() => _notice = notice);
        return;
      }
      _handlePairingIntent(
        PairingIntent.importHandoff(result),
        importNotice: notice,
      );
    } on SetupQrImageImportException catch (error) {
      if (mounted) {
        setState(
          () => _notice = _setupScreenPresentation.qrImportFailureNotice(
            error.message,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _notice = _setupScreenPresentation.qrImportFailureNotice(),
        );
      }
    } finally {
      if (mounted) setState(() => _importingQr = false);
    }
  }

  Future<void> _startConnectIntentHandling() async {
    final available = await _connectIntentSource.isAvailable();
    if (!mounted || !available) return;
    final result = await _connectIntentSource.initialImport();
    if (!mounted) return;
    if (result != null && result.hasValues) {
      _applyConnectIntentImport(result);
    }
    _connectIntentSubscription = _connectIntentSource.imports.listen(
      _applyConnectIntentImport,
    );
  }

  void _applyConnectIntentImport(SetupQrImageImport result) {
    if (!mounted || !result.hasValues) return;
    _handlePairingIntent(
      PairingIntent.importHandoff(result),
      importNotice: _setupScreenPresentation.connectIntentImportNotice,
      allowImmediateImportedConnect: true,
    );
  }

  void _applyConnectionImport(
    SetupQrImageImport result,
    SetupScreenNotice notice,
  ) {
    setState(() {
      if (result.baseUrl != null) {
        const presentation = GatewayConnectionPresentation();
        final parsed = presentation.splitBaseUrl(result.baseUrl!);
        if (!parsed.hasError) {
          _scheme = Uri.tryParse(parsed.baseUrl!)?.scheme ?? 'http';
          _addressController.text = parsed.address!;
          _portController.text = parsed.port!;
        }
      }
      if (result.token != null) {
        _tokenController.text = result.token!;
      }
      _webSocketUrl = result.webSocketUrl;
      _handoffFlow = PairingHandoffFlow.fromImport(result);
      _notice = notice;
    });
  }

  void _handleAddressChanged(String value) {
    _webSocketUrl = null;
    _handoffFlow = _handoffFlow.applyManualConnectionEdit(
      PairingHandoffManualEdit.address,
    );
    final uri = Uri.tryParse(value.trim());
    if (uri != null && navivoxIsEndpointScheme(uri.scheme)) {
      _scheme = navivoxHttpSchemeFromEndpointScheme(uri.scheme);
    } else {
      _scheme = 'http';
    }
  }

  void _handlePortChanged(String _) {
    _webSocketUrl = null;
    _handoffFlow = _handoffFlow.applyManualConnectionEdit(
      PairingHandoffManualEdit.port,
    );
  }

  Future<void> _confirmActiveGatewayHandoff(SetupQrImageImport import) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _setupScreenPresentation.activeGatewayConfirmationTitle(
            _handoffFlow.safeSourceLabel(),
          ),
        ),
        content: Text(
          _setupScreenPresentation.activeGatewayConfirmationMessage(
            _safeHandoffHostSummary(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              _setupScreenPresentation.activeGatewayCancelButtonLabel,
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              _setupScreenPresentation.activeGatewayConfirmButtonLabel,
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _handlePairingIntent(PairingIntent.confirmHandoff(import));
    }
  }

  String _safeHandoffHostSummary() {
    return _setupScreenPresentation.handoffHostSummary(
      scheme: _scheme,
      address: _addressController.text,
      port: _portController.text,
    );
  }

  Future<void> _submitManualPairingHandoff() {
    return _handlePairingIntent(
      PairingIntent.submitManualHandoff(
        baseUrl: _safeHandoffHostSummary(),
        token: _tokenController.text,
        webSocketUrl: _webSocketUrl,
      ),
    );
  }

  Future<void> _handlePairingIntent(
    PairingIntent intent, {
    SetupScreenNotice? importNotice,
    bool allowImmediateImportedConnect = false,
  }) async {
    final hasActiveGateway = ref
        .read(gatewayNavivoxChannelProvider)
        .state
        .hasServers;
    final plan = const PairingIntentCoordinator().plan(
      intent,
      hasActiveGateway: hasActiveGateway,
      allowImmediateImportedConnect: allowImmediateImportedConnect,
    );
    for (final effect in plan.effects) {
      await _applyPairingIntentEffect(effect, importNotice: importNotice);
    }
  }

  Future<void> _applyPairingIntentEffect(
    PairingIntentEffect effect, {
    SetupScreenNotice? importNotice,
  }) async {
    switch (effect) {
      case ApplyPairingImportEffect(import: final handoffImport):
        _applyConnectionImport(
          handoffImport.import,
          importNotice ?? _setupScreenPresentation.connectIntentImportNotice,
        );
      case RequestPairingConfirmationEffect(import: final handoffImport):
        unawaited(_confirmActiveGatewayHandoff(handoffImport.import));
      case ConnectPairingEffect(:final intent):
        await _connectGateway(intent);
      case IgnorePairingIntentEffect():
        return;
    }
  }

  Future<void> _connectGateway(PairingIntent intent) async {
    const presentation = GatewayConnectionPresentation();
    final validationError = presentation.validateAddressAndPort(
      address: _addressController.text,
      port: _portController.text,
      scheme: _scheme,
    );
    if (validationError != null) {
      setState(() {
        _notice = _setupScreenPresentation.validationFailureNotice(
          validationError,
        );
      });
      return;
    }
    final request = presentation.connectRequestFromParts(
      address: _addressController.text,
      port: _portController.text,
      token: _tokenController.text,
      scheme: _scheme,
      webSocketUrl: _webSocketUrl,
    );

    final autoConnect =
        intent.action == PairingIntentAction.confirmHandoff &&
        intent.source != PairingHandoffSource.manual;
    setState(() {
      _connecting = true;
      _notice = autoConnect ? _setupScreenPresentation.autoConnectNotice : null;
    });
    try {
      final channel = ref.read(gatewayNavivoxChannelProvider);
      await channel.connect(
        baseUrl: request.baseUrl,
        token: request.token,
        webSocketUrl: request.webSocketUrl,
      );
      final outcome = _handoffFlow.afterConnect(channel.state);
      final contact = outcome.profileContactToSelect;
      if (contact != null) {
        channel.selectProfileContact(
          serverId: contact.serverId,
          profileId: contact.profileId,
        );
      }
      if (mounted) {
        NavigationIntent.go(context, outcome.navigationIntent);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _notice = intent.source == PairingHandoffSource.directAppOpen
              ? _setupScreenPresentation.directPairingConnectFailureNotice
              : _setupScreenPresentation.connectFailureNotice,
        );
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _copySetupGuideEntry(SetupGuideEntry entry) async {
    setState(() => _notice = null);
    try {
      await Clipboard.setData(ClipboardData(text: entry.clipboardText));
      if (mounted) {
        setState(() => _notice = SetupScreenNotice.info(entry.successMessage));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _notice = SetupScreenNotice.error(entry.failureMessage));
      }
    }
  }
}

IconData _setupGuideIcon(SetupGuideEntryId id) => switch (id) {
  SetupGuideEntryId.bootstrap => Icons.content_copy,
  SetupGuideEntryId.navivoxPairHandoff => Icons.qr_code_2,
};

Future<SetupQrImageImport?> importNavivoxQrImage() async {
  final image = await ImagePicker().pickImage(source: ImageSource.gallery);
  if (image == null) return null;

  final scanner = MobileScannerController(autoStart: false);
  try {
    final capture = await scanner.analyzeImage(
      image.path,
      formats: const [BarcodeFormat.qrCode],
    );
    for (final barcode in capture?.barcodes ?? const <Barcode>[]) {
      final payload = barcode.rawValue ?? barcode.displayValue;
      if (payload == null) continue;
      final result = parseNavivoxQrPayload(payload);
      if (result != null && result.hasValues) return result;
    }
    throw const SetupQrImageImportException(
      'No Navivox connection details were found in the QR image.',
    );
  } on SetupQrImageImportException {
    rethrow;
  } on UnsupportedError {
    throw const SetupQrImageImportException(
      'QR image import is not supported on this platform.',
    );
  } catch (_) {
    throw const SetupQrImageImportException(
      'Could not read a Navivox QR image.',
    );
  } finally {
    scanner.dispose();
  }
}
