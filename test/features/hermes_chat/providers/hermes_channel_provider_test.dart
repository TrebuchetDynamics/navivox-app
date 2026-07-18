import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';

import '../support/fake_hermes_channel.dart';
import '../support/fake_hermes_endpoint_store.dart';
import '../support/fake_hermes_gateway_directory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('channel starts disconnected instead of auto-connecting', () {
    final container = ProviderContainer(
      overrides: [
        hermesEndpointStoreProvider.overrideWithValue(
          FakeHermesEndpointStore(),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(hermesChannelProvider).state.status,
      HermesConnectionStatus.disconnected,
    );
  });

  test(
    'directory refreshes saved gateways without opening a channel',
    () async {
      final channel = FakeHermesChannel.disconnected();
      final container = ProviderContainer(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesEndpointStoreProvider.overrideWithValue(
            FakeHermesEndpointStore(
              profiles: const [
                HermesEndpointConfig(id: 'a', baseUrl: 'https://a'),
                HermesEndpointConfig(id: 'b', baseUrl: 'https://b'),
              ],
            ),
          ),
          hermesGatewaySummaryLoaderProvider.overrideWithValue(
            FakeGatewaySummaryLoader({
              'a': gatewaySummary(['a1']),
              'b': gatewaySummary(['b1']),
            }),
          ),
          gatewayContactCacheProvider.overrideWithValue(
            FakeGatewayContactCache(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final directory = container.read(hermesGatewayDirectoryProvider);
      while (directory.refreshing || directory.contacts.length < 2) {
        await Future<void>.delayed(Duration.zero);
      }

      expect(directory.contacts, hasLength(2));
      expect(channel.connectCalls, isEmpty);
    },
  );
}
