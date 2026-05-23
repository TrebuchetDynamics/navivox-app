import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/channel/navivox_channel_provider.dart';
import '../../../router/app_routes.dart';
import '../gateway_connection_presentation.dart';
import '../setup_guide_presentation.dart';
import '../setup_qr_import_presentation.dart';
import '../setup_screen_presentation.dart';

export '../setup_qr_import_presentation.dart'
    show SetupQrImageImport, parseNavivoxQrPayload;

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
  const SetupScreen({this.qrImageImporter, super.key});

  final SetupQrImageImporter? qrImageImporter;

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _baseUrlController = TextEditingController(
    text: 'http://127.0.0.1:8765',
  );
  final _tokenController = TextEditingController();
  bool _connecting = false;
  bool _showToken = false;
  bool _importingQr = false;
  SetupScreenNotice? _notice;

  @override
  void dispose() {
    _baseUrlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Navivox')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _setupScreenPresentation.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(_setupScreenPresentation.pairingInstructions),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _setupScreenPresentation.networkHint,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Semantics(
                    label: _setupScreenPresentation.baseUrlFieldSemanticLabel,
                    hint: _setupScreenPresentation.baseUrlFieldSemanticHint,
                    textField: true,
                    child: TextField(
                      controller: _baseUrlController,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: _setupScreenPresentation.baseUrlFieldLabel,
                      ),
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Semantics(
                    label: _setupScreenPresentation.tokenFieldSemanticLabel,
                    hint: _setupScreenPresentation.tokenFieldSemanticHint,
                    textField: true,
                    obscured: !_showToken,
                    child: TextField(
                      controller: _tokenController,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: _setupScreenPresentation.tokenFieldLabel,
                      ),
                      obscureText: !_showToken,
                      textInputAction: TextInputAction.done,
                      onSubmitted: _connecting
                          ? null
                          : (_) => _connectGateway(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        key: const ValueKey('setup-import-qr-button'),
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
                          _setupScreenPresentation.importQrButtonLabel,
                        ),
                      ),
                      TextButton.icon(
                        key: const ValueKey('setup-token-visibility-button'),
                        onPressed: () {
                          setState(() => _showToken = !_showToken);
                        },
                        icon: Icon(
                          _showToken ? Icons.visibility_off : Icons.visibility,
                        ),
                        label: Text(
                          _setupScreenPresentation.tokenVisibilityLabel(
                            showToken: _showToken,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_notice != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _notice!.message,
                      style: TextStyle(
                        color: _notice!.isError
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    if (_notice!.recoveryMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(_notice!.recoveryMessage!),
                    ],
                  ],
                  const SizedBox(height: 12),
                  Semantics(
                    label: _setupScreenPresentation.connectButtonLabel,
                    hint: _setupScreenPresentation.connectButtonSemanticHint,
                    button: true,
                    enabled: !_connecting,
                    onTap: _connecting ? null : _connectGateway,
                    child: ExcludeSemantics(
                      child: FilledButton.icon(
                        onPressed: _connecting ? null : _connectGateway,
                        icon: _connecting
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.hub),
                        label: Text(
                          _setupScreenPresentation.connectButtonLabel,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _setupGuidePresentation.introCopy,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          for (final entry
                              in _setupGuidePresentation.entries) ...[
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
                  ),
                ],
              ),
            ),
          ),
        ),
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
      final result = await importer();
      if (!mounted) return;
      final notice = _setupScreenPresentation.qrImportNotice(result);
      if (result == null || !result.hasValues) {
        setState(() => _notice = notice);
        return;
      }
      setState(() {
        if (result.baseUrl != null) {
          _baseUrlController.text = result.baseUrl!;
        }
        if (result.token != null) {
          _tokenController.text = result.token!;
        }
        _notice = notice;
      });
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

  Future<void> _connectGateway() async {
    const presentation = GatewayConnectionPresentation();
    final validationError = presentation.validateBaseUrl(
      _baseUrlController.text,
    );
    if (validationError != null) {
      setState(() {
        _notice = _setupScreenPresentation.validationFailureNotice(
          validationError,
        );
      });
      return;
    }
    final request = presentation.connectRequest(
      baseUrl: _baseUrlController.text,
      token: _tokenController.text,
    );

    setState(() {
      _connecting = true;
      _notice = null;
    });
    try {
      await ref
          .read(gatewayNavivoxChannelProvider)
          .connect(baseUrl: request.baseUrl, token: request.token);
      if (mounted) context.go(AppRoutes.chats);
    } catch (_) {
      if (mounted) {
        setState(() => _notice = _setupScreenPresentation.connectFailureNotice);
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
  SetupGuideEntryId.downloadLinks => Icons.link,
  SetupGuideEntryId.postInstallChecks => Icons.checklist,
  SetupGuideEntryId.navivoxPairHandoff => Icons.qr_code_2,
  SetupGuideEntryId.gatewayLifecycle => Icons.terminal,
  SetupGuideEntryId.bootHelper => Icons.power_settings_new,
  SetupGuideEntryId.connectionHint => Icons.device_hub,
  SetupGuideEntryId.storageCommand => Icons.folder_shared,
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
