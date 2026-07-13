import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:navivox/features/needle_spike/needle_spike_flag.dart';
import 'package:navivox/router/app_routes.dart';
import 'package:navivox/router/providers/app_router.dart';

void main() {
  test('needle spike route is absent unless NEEDLE_SPIKE is defined', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    final topLevelPaths = router.configuration.routes.whereType<GoRoute>().map(
      (r) => r.path,
    );
    if (needleSpikeEnabled) {
      expect(topLevelPaths, contains(AppRoutes.needleSpike));
    } else {
      expect(topLevelPaths, isNot(contains(AppRoutes.needleSpike)));
    }
  });
}
