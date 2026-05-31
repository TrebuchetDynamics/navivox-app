import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/protocol/navivox_memory.dart';

void main() {
  test('memory degradation aliases share non-empty reason semantics', () {
    final search = NavivoxMemorySearchResult.fromJson({
      'items': const [],
      'reason': ' degraded via alias ',
    });
    final detail = NavivoxMemoryDetail.fromJson({
      'id': 'memory-1',
      'type': 'memory_items',
      'content': 'memory',
      'degraded_reason': ' degraded via canonical field ',
    });
    final action = NavivoxMemoryActionResult.fromJson({
      'accepted': false,
      'action': 'archive',
      'message': 'not now',
      'degraded_reason': '   ',
    });

    expect(search.isDegraded, isTrue);
    expect(search.degradedReason, 'degraded via alias');
    expect(detail.isDegraded, isTrue);
    expect(detail.degradedReason, 'degraded via canonical field');
    expect(action.isDegraded, isFalse);
  });
}
