import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact_cache.dart';

void main() {
  test(
    'cache restores contacts offline and removes one gateway only',
    () async {
      SharedPreferences.setMockInitialValues({});
      final cache = GatewayContactCache();
      final contacts = [
        const GatewayContact(
          id: GatewayContactId(gatewayId: 'a', profileId: 'p1'),
          gatewayLabel: 'Alpha',
          profileName: 'One',
          sessionCount: 0,
          availability: GatewayAvailability.online,
        ),
        const GatewayContact(
          id: GatewayContactId(gatewayId: 'b', profileId: 'p2'),
          gatewayLabel: 'Beta',
          profileName: 'Two',
          sessionCount: 0,
          availability: GatewayAvailability.online,
        ),
      ];

      await cache.save(contacts);
      await cache.removeGateway('a');
      final restored = await cache.load();

      expect(restored, hasLength(1));
      expect(restored.single.id.gatewayId, 'b');
      expect(restored.single.availability, GatewayAvailability.offline);
    },
  );
}
