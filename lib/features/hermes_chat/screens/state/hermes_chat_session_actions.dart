part of '../hermes_chat_screen.dart';

extension _HermesChatScreenSessionActions on _HermesChatScreenState {
  Future<void> _createSession(
    BuildContext context,
    HermesChannel channel,
  ) async {
    try {
      await channel.createSession();
      _refreshActiveGatewayContact();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not create session: ${_safeHermesUiError(error)}',
          ),
        ),
      );
    }
  }

  Future<void> _selectSession(
    BuildContext context,
    HermesChannel channel,
    HermesSession session,
  ) async {
    try {
      await channel.selectSession(session.id);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open session: ${_safeHermesUiError(error)}'),
        ),
      );
    }
  }

  Future<void> _renameSession(
    BuildContext context,
    HermesChannel channel,
    HermesSession session,
  ) async {
    final currentTitle = session.title ?? '';
    var draftTitle = _safeHermesRenameDefault(currentTitle);
    final nextTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename session'),
        content: TextFormField(
          key: const ValueKey('hermes-session-title-field'),
          initialValue: draftTitle,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Session title'),
          onChanged: (value) => draftTitle = value,
          onFieldSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('hermes-session-title-save'),
            onPressed: () => Navigator.of(context).pop(draftTitle.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final title = nextTitle?.trim();
    if (title == null || title.isEmpty || title == currentTitle) return;
    try {
      await channel.renameSession(sessionId: session.id, title: title);
      _refreshActiveGatewayContact();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not rename session: ${_safeHermesUiError(error)}',
          ),
        ),
      );
    }
  }

  Future<void> _forkSession(
    BuildContext context,
    HermesChannel channel,
    HermesSession session,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Branch this session?'),
        content: Text(
          'Create a new session with the conversation history from “${_safeHermesUiPreview(session.title ?? session.id, maxLength: 96)}”? The original remains in Hermes and the new branch becomes active.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('hermes-session-branch-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Create branch'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await channel.forkSession(session.id);
      _refreshActiveGatewayContact();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Created a new session branch.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not create session branch: ${_safeHermesUiError(error)}',
          ),
        ),
      );
    }
  }

  Future<void> _deleteSessions(
    BuildContext context,
    HermesChannel channel,
    List<HermesSession> sessions,
  ) async {
    final selected = <HermesSession>[];
    final seen = <String>{};
    for (final session in sessions) {
      if (seen.add(session.id) &&
          channel.state.sessions.any((item) => item.id == session.id) &&
          !channel.state.isSessionStreaming(session.id)) {
        selected.add(session);
      }
    }
    if (selected.isEmpty) return;
    final count = selected.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $count sessions?'),
        content: const Text(
          'Delete the selected sessions from Hermes? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('hermes-sessions-delete-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    var deleted = 0;
    for (final session in selected) {
      if (channel.state.isSessionStreaming(session.id) ||
          !channel.state.sessions.any((item) => item.id == session.id)) {
        continue;
      }
      try {
        await channel.deleteSession(session.id);
        deleted += 1;
      } catch (_) {
        // Keep deleting the remaining selected sessions. The final bounded
        // summary reports partial failure without exposing server payloads.
      }
    }
    _refreshActiveGatewayContact();
    if (!context.mounted) return;
    final message = deleted == count
        ? 'Deleted $deleted ${deleted == 1 ? 'session' : 'sessions'}.'
        : 'Deleted $deleted of $count sessions. ${count - deleted} could not be deleted.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _deleteSession(
    BuildContext context,
    HermesChannel channel,
    HermesSession session,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete session?'),
        content: Text(
          'Delete "${_safeHermesUiPreview(session.title ?? session.id, maxLength: 96)}" from Hermes?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('hermes-session-delete-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await channel.deleteSession(session.id);
      _refreshActiveGatewayContact();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not delete session: ${_safeHermesUiError(error)}',
          ),
        ),
      );
    }
  }
}
