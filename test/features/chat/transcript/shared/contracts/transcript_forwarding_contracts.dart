import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/protocol/navivox_event.dart';

/// Shared callback contract for Transcript tests that forward a message to a
/// Profile contact target.
typedef TranscriptForwardCallback =
    void Function(NavivoxChatMessage message, NavivoxProfileContact target);
