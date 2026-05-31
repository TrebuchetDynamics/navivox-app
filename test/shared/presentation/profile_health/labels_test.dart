import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/shared/presentation/profile_health_labels.dart';

void main() {
  test('formats full and compact profile health labels consistently', () {
    expect(profileHealthLabel(NavivoxProfileHealth.online), 'online');
    expect(profileHealthLabel(NavivoxProfileHealth.offline), 'offline');
    expect(profileHealthLabel(NavivoxProfileHealth.needsAuth), 'auth required');
    expect(profileHealthLabel(NavivoxProfileHealth.warning), 'warning');

    expect(compactProfileHealthLabel(NavivoxProfileHealth.online), 'online');
    expect(compactProfileHealthLabel(NavivoxProfileHealth.offline), 'offline');
    expect(compactProfileHealthLabel(NavivoxProfileHealth.needsAuth), 'auth');
    expect(compactProfileHealthLabel(NavivoxProfileHealth.warning), 'warning');
  });
}
