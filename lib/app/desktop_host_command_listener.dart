import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../router/app_router.dart';
import '../router/app_routes.dart';

abstract final class WingDesktopHostCommands {
  static const channelName =
      'com.trebuchetdynamics.hermes.wing/desktop_host_commands';
  static const openSettings = 'openSettings';
}

/// Receives bounded commands from a trusted native desktop shell.
///
/// Native commands only select existing Wing routes. They do not call Hermes
/// Agent or bypass any capability checks owned by those routes.
class DesktopHostCommandListener extends ConsumerStatefulWidget {
  const DesktopHostCommandListener({
    required this.child,
    this.channel = const MethodChannel(WingDesktopHostCommands.channelName),
    super.key,
  });

  final Widget child;
  final MethodChannel channel;

  @override
  ConsumerState<DesktopHostCommandListener> createState() =>
      _DesktopHostCommandListenerState();
}

class _DesktopHostCommandListenerState
    extends ConsumerState<DesktopHostCommandListener> {
  @override
  void initState() {
    super.initState();
    widget.channel.setMethodCallHandler(_handleMethodCall);
  }

  @override
  void didUpdateWidget(DesktopHostCommandListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.channel, widget.channel)) return;
    oldWidget.channel.setMethodCallHandler(null);
    widget.channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method != WingDesktopHostCommands.openSettings || !mounted) {
      return;
    }
    _openSettings();
  }

  void _openSettings() {
    if (!mounted) return;
    ref.read(routerProvider).go(AppRoutes.settings);
  }

  @override
  void dispose() {
    widget.channel.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.comma, control: true):
          _openSettings,
      const SingleActivator(LogicalKeyboardKey.comma, meta: true):
          _openSettings,
    },
    child: widget.child,
  );
}
