import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_routes.dart';

/// Informational banner steering operators from a Gormes-only screen toward
/// the native Hermes Agent experience, per ADR 0007's plan to deprecate the
/// preserved `/v1/navivox/*` runtime in favor of Hermes. Purely additive:
/// does not hide or remove the screen it's placed on.
class GormesLegacyNotice extends StatelessWidget
    implements PreferredSizeWidget {
  const GormesLegacyNotice({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(36);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      key: const ValueKey('gormes-legacy-notice'),
      color: colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'This is a legacy Gormes screen. Navivox is moving to '
                'Hermes Agent.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            TextButton(
              key: const ValueKey('gormes-legacy-notice-hermes-button'),
              onPressed: () => GoRouter.of(context).go(AppRoutes.hermes),
              child: const Text('Open Hermes'),
            ),
          ],
        ),
      ),
    );
  }
}
