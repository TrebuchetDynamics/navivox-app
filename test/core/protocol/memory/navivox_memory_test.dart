import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/protocol/navivox_memory.dart';

void main() {
  group('memory overview database label', () {
    test('redacts unix absolute database paths to basename', () {
      final overview = NavivoxMemoryOverview.fromJson({
        'database_path': '/var/lib/navivox/profiles/mineru/memory.db',
      });

      expect(overview.databaseLabel, 'redacted/memory.db');
      expect(overview.databaseLabel, isNot(contains('/var/lib/navivox')));
    });

    test('redacts windows absolute database paths to basename', () {
      final overview = NavivoxMemoryOverview.fromJson({
        'database_path': r'C:\Users\xel\navivox\profiles\mineru\memory.db',
      });

      expect(overview.databaseLabel, 'redacted/memory.db');
      expect(overview.databaseLabel, isNot(contains(r'C:\Users\xel')));
    });

    test('keeps gormes-relative database labels recognizable', () {
      final overview = NavivoxMemoryOverview.fromJson({
        'database_path': '/home/xel/.gormes/profiles/mineru/memory.db',
      });

      expect(overview.databaseLabel, '~/.gormes/profiles/mineru/memory.db');
      expect(overview.databaseLabel, isNot(contains('/home/xel')));
    });

    test('keeps windows gormes-relative database labels recognizable', () {
      final overview = NavivoxMemoryOverview.fromJson({
        'database_path': r'C:\Users\xel\.gormes\profiles\mineru\memory.db',
      });

      expect(overview.databaseLabel, '~/.gormes/profiles/mineru/memory.db');
      expect(overview.databaseLabel, isNot(contains(r'C:\Users\xel')));
    });
  });

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
