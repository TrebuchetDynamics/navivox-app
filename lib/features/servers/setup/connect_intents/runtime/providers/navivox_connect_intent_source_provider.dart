import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sources/navivox_connect_intent_source.dart';

final navivoxConnectIntentSourceProvider = Provider<NavivoxConnectIntentSource>(
  (ref) => NavivoxConnectIntentSource(),
);
