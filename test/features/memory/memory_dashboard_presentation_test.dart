import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/protocol/navivox_memory.dart';
import 'package:navivox/features/memory/memory_dashboard_presentation.dart';

void main() {
  const presentation = MemoryDashboardPresentation();

  test('builds overview scope and count presentation with safe fallbacks', () {
    final overview = NavivoxMemoryOverview(
      profileId: 'mineru',
      workspaceId: 'gormes',
      databaseLabel: '~/.gormes/profiles/mineru/memory.db',
      health: NavivoxMemoryHealth.active,
      totalTurns: 120,
      activeMemoryItems: 12,
      observations: 34,
      conclusions: 5,
      sessionSummaries: 7,
      entities: 18,
      relationships: 21,
      lastUpdatedAt: DateTime.utc(2026, 5, 21, 15, 28, 18),
    );
    const contact = NavivoxProfileContact(
      serverId: 'local',
      profileId: 'mineru',
      displayName: ' ',
      serverLabel: ' ',
      health: NavivoxProfileHealth.online,
      latestPreview: 'Ready',
    );

    final model = presentation.overviewFor(overview, activeProfile: contact);

    expect(model.healthLabel, 'Goncho active');
    expect(model.serverLine, 'Server: default');
    expect(model.profileLine, 'Profile: mineru');
    expect(model.workspaceLine, 'Workspace: gormes');
    expect(model.databaseTitle, 'Database');
    expect(model.databaseLabel, '~/.gormes/profiles/mineru/memory.db');
    expect(model.lastUpdatedLine, 'Last updated: 2026-05-21T15:28:18.000Z');
    expect(model.counts.map((count) => '${count.label}:${count.count}'), [
      'Turns:120',
      'Active memory items:12',
      'Observations:34',
      'Conclusions:5',
      'Session summaries:7',
      'Entities:18',
      'Relationships:21',
    ]);
  });

  test(
    'classifies memory readiness states from overview health and counts',
    () {
      expect(presentation.checkingReadiness().statusLabel, 'Checking memory');
      expect(
        presentation
            .unavailableReadiness(message: 'Gormes memory API is unavailable.')
            .statusLabel,
        'Memory unavailable',
      );

      final ready = presentation.readinessFor(
        const NavivoxMemoryOverview(
          profileId: 'mineru',
          workspaceId: 'gormes',
          databaseLabel: '~/.gormes/profiles/mineru/memory.db',
          health: NavivoxMemoryHealth.active,
          totalTurns: 1,
          activeMemoryItems: 0,
          observations: 0,
          conclusions: 0,
          sessionSummaries: 0,
          entities: 0,
          relationships: 0,
        ),
      );
      final degraded = presentation.readinessFor(
        const NavivoxMemoryOverview.degraded(
          profileId: 'mineru',
          reason: 'Gormes memory API is unavailable.',
        ),
      );
      final empty = presentation.readinessFor(
        const NavivoxMemoryOverview(
          profileId: 'mineru',
          workspaceId: 'gormes',
          databaseLabel: '~/.gormes/profiles/mineru/memory.db',
          health: NavivoxMemoryHealth.active,
          totalTurns: 0,
          activeMemoryItems: 0,
          observations: 0,
          conclusions: 0,
          sessionSummaries: 0,
          entities: 0,
          relationships: 0,
        ),
      );

      expect(ready.status, MemoryReadinessStatus.ready);
      expect(degraded.status, MemoryReadinessStatus.degraded);
      expect(degraded.message, contains('Gormes memory API is unavailable.'));
      expect(empty.status, MemoryReadinessStatus.empty);
    },
  );

  test('builds search copy and memory item metadata presentation', () {
    expect(presentation.searchTitle, 'Search & Browse');
    expect(presentation.searchFieldLabel, 'Search memories');
    expect(
      presentation.searchUnavailableMessage,
      'Gormes memory search API is unavailable.',
    );
    expect(presentation.emptySearchMessage, 'No memories found.');

    const item = NavivoxMemoryItem(
      id: 'mem-1',
      type: NavivoxMemoryType.memoryItems,
      snippet: 'Mineru uses Goncho memory for workspace recall.',
      sessionId: 's-1',
      peerId: 'mineru',
      status: 'current',
      tags: ['workspace', 'recall'],
    );

    final card = presentation.itemFor(item);

    expect(card.keyValue, 'memory-item-memory_items-mem-1');
    expect(card.title, 'Mineru uses Goncho memory for workspace recall.');
    expect(card.metadataLine, 'memory_items · current · s-1 · mineru');
    expect(card.tags, ['workspace', 'recall']);

    final blank = presentation.itemFor(
      const NavivoxMemoryItem(
        id: 'blank',
        type: NavivoxMemoryType.observations,
        snippet: 'No metadata',
      ),
    );

    expect(blank.metadataLine, 'observations');
  });

  test('builds detail rows and safe management action copy', () {
    const detail = NavivoxMemoryDetail(
      id: 'mem-1',
      type: NavivoxMemoryType.memoryItems,
      content: 'Mineru uses Goncho memory for workspace recall.',
      source: 'goncho_memory_items',
      sessionId: 's-1',
      peerId: 'mineru',
      createdAt: '2026-05-21T15:30:00Z',
      status: 'current',
      provenance: 'derived from reviewed session s-1',
      linkedEntities: ['Mineru'],
      linkedRelationships: ['Mineru RELATED_TO Goncho'],
    );

    final model = presentation.detailFor(detail);

    expect(model.title, 'Memory detail');
    expect(model.content, detail.content);
    expect(model.rows.map((row) => row.line), [
      'Type: memory_items',
      'Source: goncho_memory_items',
      'Session: s-1',
      'Peer: mineru',
      'Status: current',
      'Created: 2026-05-21T15:30:00Z',
    ]);
    expect(model.provenanceTitle, 'Provenance');
    expect(model.linkedEntitiesTitle, 'Linked entities');
    expect(model.linkedRelationshipsTitle, 'Linked relationships');
    expect(model.rawSourcePreservedLabel, 'Raw source preserved');
    expect(
      model.actions.map((action) => '${action.type.wireValue}:${action.label}'),
      [
        'pin:Pin',
        'archive:Archive',
        'mark_stale:Mark stale',
        'add_correction:Add correction',
      ],
    );
    expect(model.actions.last.requiresCorrection, isTrue);
  });

  test('builds degraded, correction, and action feedback copy', () {
    const contact = NavivoxProfileContact(
      serverId: 'local',
      profileId: 'mineru',
      displayName: 'Mineru Builder',
      serverLabel: 'local',
      health: NavivoxProfileHealth.warning,
      latestPreview: 'Memory API unavailable',
    );

    final error = presentation.errorFor(
      contact,
      message: 'Gormes memory API is unavailable.',
    );

    expect(error.title, 'Memory degraded');
    expect(error.profileLine, 'Profile: Mineru Builder');
    expect(error.message, 'Gormes memory API is unavailable.');
    expect(
      presentation.detailUnavailableMessage,
      'Gormes memory detail API is unavailable.',
    );
    expect(presentation.correctionDialogTitle, 'Add correction');
    expect(presentation.correctionFieldLabel, 'Correction note');
    expect(
      presentation.correctionFieldHelperText,
      'Adds a superseding note; raw source is preserved.',
    );
    expect(presentation.cancelLabel, 'Cancel');
    expect(presentation.saveCorrectionLabel, 'Save correction');

    expect(
      presentation.actionMessageFor(
        const NavivoxMemoryActionResult(
          accepted: true,
          action: NavivoxMemoryActionType.archive,
          message: 'Archive requested.',
        ),
        requestedAction: NavivoxMemoryActionType.archive,
      ),
      'Archive requested.',
    );
    expect(
      presentation.actionMessageFor(
        const NavivoxMemoryActionResult(
          accepted: true,
          action: NavivoxMemoryActionType.pin,
          message: ' ',
        ),
        requestedAction: NavivoxMemoryActionType.pin,
      ),
      'Pin requested.',
    );
    expect(
      presentation.actionMessageFor(
        const NavivoxMemoryActionResult.degraded(
          action: NavivoxMemoryActionType.archive,
          reason: 'Gormes memory action API is unavailable.',
        ),
        requestedAction: NavivoxMemoryActionType.archive,
      ),
      'Gormes memory action API is unavailable.',
    );
  });
}
