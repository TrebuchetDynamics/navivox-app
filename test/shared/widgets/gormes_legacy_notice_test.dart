import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:navivox/router/app_routes.dart';
import 'package:navivox/shared/widgets/gormes_legacy_notice.dart';

void main() {
  Widget wrap({required Widget home}) {
    return MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/start',
        routes: [
          GoRoute(path: '/start', builder: (context, state) => home),
          GoRoute(
            path: AppRoutes.hermes,
            builder: (context, state) => const Scaffold(
              body: Text(
                'Hermes screen',
                key: ValueKey('hermes-screen-marker'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  testWidgets('shows the legacy Gormes notice with a link to Hermes', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(home: const Scaffold(body: GormesLegacyNotice())),
    );

    expect(find.byKey(const ValueKey('gormes-legacy-notice')), findsOneWidget);
    expect(find.textContaining('legacy Gormes'), findsOneWidget);
  });

  testWidgets('tapping the action navigates to the Hermes screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(home: const Scaffold(body: GormesLegacyNotice())),
    );

    await tester.tap(
      find.byKey(const ValueKey('gormes-legacy-notice-hermes-button')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('hermes-screen-marker')), findsOneWidget);
  });
}
