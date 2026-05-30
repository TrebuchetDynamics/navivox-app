import '../../core/channel/navivox_channel.dart';

String profileHealthLabel(NavivoxProfileHealth health) {
  return switch (health) {
    NavivoxProfileHealth.online => 'online',
    NavivoxProfileHealth.offline => 'offline',
    NavivoxProfileHealth.needsAuth => 'auth required',
    NavivoxProfileHealth.warning => 'warning',
  };
}

String compactProfileHealthLabel(NavivoxProfileHealth health) {
  return switch (health) {
    NavivoxProfileHealth.online => 'online',
    NavivoxProfileHealth.offline => 'offline',
    NavivoxProfileHealth.needsAuth => 'auth',
    NavivoxProfileHealth.warning => 'warning',
  };
}
