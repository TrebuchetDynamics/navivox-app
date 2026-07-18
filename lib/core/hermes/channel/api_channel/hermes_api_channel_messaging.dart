part of '../hermes_api_channel.dart';

extension _MessagingExtension on HermesApiChannel {
  Future<void> _sendText(
    String text, {
    String? imageDataUrl,
    String? textAttachment,
    String? attachmentName,
  }) async {
    final message = text.trim();
    final image = imageDataUrl?.trim();
    final hasImage = image != null && image.isNotEmpty;
    final hasTextFile = textAttachment != null;
    if (message.isEmpty && !hasImage && !hasTextFile) {
      throw ArgumentError.value(
        text,
        'text',
        'Hermes message cannot be blank.',
      );
    }
    if (hasImage && hasTextFile) {
      throw ArgumentError('Send either an image or a text file, not both.');
    }
    if (hasImage &&
        !image.startsWith(RegExp(r'data:image/(png|jpeg|gif|webp);base64,'))) {
      throw ArgumentError.value(
        imageDataUrl,
        'imageDataUrl',
        'Hermes attachments must be supported image data URLs.',
      );
    }
    final attachmentLabel = attachmentName?.trim();
    final safeLabel = attachmentLabel?.isNotEmpty == true
        ? attachmentLabel!
        : hasTextFile
        ? 'attachment.txt'
        : 'attachment';
    final requestText = [
      if (message.isNotEmpty) message,
      if (hasTextFile)
        '<file name="${_escapeAttachmentXml(safeLabel)}" mime="text/plain">\n$textAttachment\n</file>',
    ].join('\n\n');
    final displayMessage = [
      if (message.isNotEmpty) message,
      if (hasImage) '[Image: $safeLabel]',
      if (hasTextFile) '[File: $safeLabel]',
    ].join('\n\n');
    final Object requestMessage = hasImage
        ? [
            if (requestText.isNotEmpty)
              {'type': 'input_text', 'text': requestText},
            {'type': 'input_image', 'image_url': image},
          ]
        : requestText;
    final client = _client;
    final sessionId = _state.activeSessionId;
    if (client == null || sessionId == null) {
      throw StateError('Hermes channel is not connected to a session.');
    }
    final activeCompleter = _activeStreamCompleter;
    if ((activeCompleter != null && !activeCompleter.isCompleted) ||
        _state.activeMessages.lastOrNull?.status ==
            HermesTurnStatus.streaming) {
      throw StateError('Hermes turn is already streaming.');
    }
    final capabilities = _state.capabilities;
    if (capabilities != null &&
        !HermesTransportPolicy(capabilities).supportsAnyChatTransport) {
      throw StateError(
        'Hermes did not advertise a supported chat transport for this endpoint.',
      );
    }

    final turns = List<HermesChatTurn>.from(_state.activeMessages);
    final preSendTurnCount = turns.length;
    final now = DateTime.now();
    turns.add(
      HermesChatTurn(
        id: 'local-user-${turns.length}',
        sessionId: sessionId,
        author: HermesTurnAuthor.user,
        createdAt: now,
        text: displayMessage,
      ),
    );
    var assistantTurn = HermesChatTurn(
      id: 'local-assistant-${turns.length}',
      sessionId: sessionId,
      author: HermesTurnAuthor.assistant,
      createdAt: now,
      status: HermesTurnStatus.streaming,
    );
    turns.add(assistantTurn);
    var assistantIndex = turns.length - 1;
    _setTurns(sessionId, turns, clearErrorMessage: true);

    final useRunTransport =
        capabilities != null &&
        HermesTransportPolicy(capabilities).supportsRunsTransport;

    final submissionGeneration = _streamGeneration;
    Stream<HermesStreamEvent>? events;
    String? runId;
    try {
      if (useRunTransport) {
        final run = await client.startRun(
          sessionId: sessionId,
          message: requestMessage,
        );
        runId = run.id;
      } else {
        events = client.streamSessionChat(sessionId, message: requestMessage);
      }
    } catch (error) {
      if (!identical(_client, client) ||
          _state.status != HermesConnectionStatus.connected ||
          _state.activeSessionId != sessionId ||
          _streamGeneration != submissionGeneration) {
        return;
      }
      assistantTurn = assistantTurn.copyWith(status: HermesTurnStatus.failed);
      turns[assistantIndex] = assistantTurn;
      _setTurns(sessionId, turns, errorMessage: _safeHermesError(error));
      rethrow;
    }

    if (!identical(_client, client) ||
        _state.status != HermesConnectionStatus.connected ||
        _state.activeSessionId != sessionId ||
        _streamGeneration != submissionGeneration) {
      return;
    }

    try {
      events ??= client.runEvents(runId!);
    } catch (error) {
      if (!identical(_client, client) ||
          _state.status != HermesConnectionStatus.connected ||
          _state.activeSessionId != sessionId ||
          _streamGeneration != submissionGeneration) {
        return;
      }
      assistantTurn = assistantTurn.copyWith(status: HermesTurnStatus.failed);
      turns[assistantIndex] = assistantTurn;
      final message =
          'Hermes run event stream failed to open: ${_safeHermesError(error)}';
      _setTurns(sessionId, turns, errorMessage: message);
      throw StateError(message);
    }
    _activeRunId = runId;
    final toolTurnIndexByCallId = <String, int>{};
    final completer = Completer<void>();
    final streamGeneration = _streamGeneration + 1;
    _streamGeneration = streamGeneration;
    _activeStreamCompleter = completer;
    _activeTurnStopped = false;
    var streamFailed = false;
    var streamEndedBeforeTerminal = false;
    var terminalRunEventReceived = false;
    HermesRunUsage? runUsage;
    Timer? idleTimer;
    void armIdleTimer() {
      idleTimer?.cancel();
      idleTimer = Timer(streamIdleTimeout, () {
        if (streamGeneration != _streamGeneration || completer.isCompleted) {
          return;
        }
        streamFailed = true;
        streamEndedBeforeTerminal = true;
        assistantTurn = assistantTurn.copyWith(status: HermesTurnStatus.failed);
        turns[assistantIndex] = assistantTurn;
        _setTurns(
          sessionId,
          List.of(turns),
          errorMessage:
              'Hermes event stream timed out while waiting for activity.',
        );
        completer.complete();
        unawaited(_activeStream?.cancel());
      });
    }

    _activeStream = events.listen(
      (event) {
        if (streamGeneration != _streamGeneration || terminalRunEventReceived) {
          return;
        }
        armIdleTimer();
        if (event.isDone) {
          terminalRunEventReceived = true;
          if (!completer.isCompleted) completer.complete();
          return;
        }
        final delta = _streamDelta(event);
        if (delta != null && delta.isNotEmpty) {
          assistantTurn = assistantTurn.appendDelta(delta);
          turns[assistantIndex] = assistantTurn;
          _setTurns(sessionId, List.of(turns));
          return;
        }
        if (event.name == 'reasoning.available') {
          if (_applyReasoningEvent(
            sessionId: sessionId,
            event: event,
            turns: turns,
            insertBefore: assistantIndex,
          )) {
            assistantIndex = turns.length - 1;
            _setTurns(sessionId, List.of(turns));
          }
          return;
        }
        if (_isToolEvent(event.name)) {
          _applyToolEvent(
            sessionId: sessionId,
            event: event,
            turns: turns,
            toolTurnIndexByCallId: toolTurnIndexByCallId,
            insertBefore: assistantIndex,
          );
          assistantIndex = turns.length - 1;
          _setTurns(sessionId, List.of(turns));
          return;
        }
        if (_isApprovalRequestEvent(event.name)) {
          final request = _approvalRequestFromEvent(event);
          if (request.id.isEmpty) {
            terminalRunEventReceived = true;
            streamFailed = true;
            assistantTurn = assistantTurn.copyWith(
              status: HermesTurnStatus.failed,
            );
            turns[assistantIndex] = assistantTurn;
            _setTurns(
              sessionId,
              List.of(turns),
              errorMessage:
                  'Hermes approval request was missing an approval id.',
            );
            if (!completer.isCompleted) completer.complete();
            return;
          }
          _approvalController.add(request);
          return;
        }
        if (_isStreamErrorEvent(event.name)) {
          terminalRunEventReceived = true;
          streamFailed = true;
          assistantTurn = assistantTurn.copyWith(
            status: HermesTurnStatus.failed,
          );
          turns[assistantIndex] = assistantTurn;
          _setTurns(
            sessionId,
            List.of(turns),
            errorMessage: _streamErrorMessage(event),
          );
          if (!completer.isCompleted) completer.complete();
          return;
        }
        if (_isSuccessfulTerminalRunEvent(event.name)) {
          final usageJson = wingMapFromJson(event.payload['usage']);
          if (usageJson.isNotEmpty) {
            runUsage = HermesRunUsage.fromJson(usageJson);
          }
          terminalRunEventReceived = true;
          if (!completer.isCompleted) completer.complete();
          return;
        }
        if (_isFailedTerminalRunEvent(event.name)) {
          terminalRunEventReceived = true;
          streamFailed = true;
          assistantTurn = assistantTurn.copyWith(
            status: HermesTurnStatus.failed,
          );
          turns[assistantIndex] = assistantTurn;
          _setTurns(
            sessionId,
            List.of(turns),
            errorMessage: _isCancelledTerminalRunEvent(event.name)
                ? 'Hermes run was cancelled.'
                : 'Hermes run failed.',
          );
          if (!completer.isCompleted) completer.complete();
        }
      },
      onError: (Object error) {
        idleTimer?.cancel();
        if (streamGeneration != _streamGeneration || terminalRunEventReceived) {
          return;
        }
        streamFailed = true;
        streamEndedBeforeTerminal = true;
        assistantTurn = assistantTurn.copyWith(status: HermesTurnStatus.failed);
        turns[assistantIndex] = assistantTurn;
        _setTurns(
          sessionId,
          List.of(turns),
          errorMessage: _safeHermesError(error),
        );
        if (!completer.isCompleted) completer.complete();
      },
      onDone: () {
        idleTimer?.cancel();
        if (streamGeneration != _streamGeneration) return;
        if (!terminalRunEventReceived) {
          streamFailed = true;
          streamEndedBeforeTerminal = true;
          assistantTurn = assistantTurn.copyWith(
            status: HermesTurnStatus.failed,
          );
          turns[assistantIndex] = assistantTurn;
          _setTurns(
            sessionId,
            List.of(turns),
            errorMessage: 'Hermes stream closed before a terminal event.',
          );
        }
        if (!completer.isCompleted) completer.complete();
      },
      cancelOnError: true,
    );
    armIdleTimer();
    await completer.future;
    idleTimer?.cancel();
    if (streamGeneration != _streamGeneration) {
      return;
    }
    if (terminalRunEventReceived) {
      unawaited(_activeStream?.cancel() ?? Future<void>.value());
    }
    final stoppedLocally = _activeTurnStopped;
    if (identical(_activeStreamCompleter, completer)) {
      _activeStreamCompleter = null;
      _activeTurnStopped = false;
    }
    _activeStream = null;
    _activeRunId = null;
    if (!identical(_client, client) ||
        _state.status != HermesConnectionStatus.connected ||
        _state.activeSessionId != sessionId) {
      return;
    }
    final canReadRunStatus =
        runId != null &&
        capabilities != null &&
        HermesTransportPolicy(capabilities).supportsRunStatus;
    HermesRun? recoveredRun;
    if (!stoppedLocally &&
        canReadRunStatus &&
        (streamFailed || runUsage == null)) {
      try {
        recoveredRun = await client.getRunStatus(runId);
        runUsage ??= recoveredRun.usage;
      } catch (_) {
        // Status and usage recovery are best-effort; preserve the transcript.
      }
      if (!identical(_client, client) ||
          _state.status != HermesConnectionStatus.connected ||
          _state.activeSessionId != sessionId ||
          streamGeneration != _streamGeneration) {
        return;
      }
    }
    if (assistantTurn.status == HermesTurnStatus.streaming) {
      assistantTurn = stoppedLocally
          ? assistantTurn.copyWith(
              status: HermesTurnStatus.failed,
              text: assistantTurn.text.isEmpty
                  ? 'Stopped.'
                  : assistantTurn.text,
            )
          : assistantTurn.copyWith(
              status: HermesTurnStatus.completed,
              usage: runUsage,
            );
      turns[assistantIndex] = assistantTurn;
      _setTurns(sessionId, List.of(turns));
    }

    if (streamFailed && streamEndedBeforeTerminal && !stoppedLocally) {
      final recoveredOutput = recoveredRun?.output?.trim();
      if (recoveredRun?.status == HermesRunLifecycle.completed &&
          recoveredOutput?.isNotEmpty == true) {
        assistantTurn = assistantTurn.copyWith(
          status: HermesTurnStatus.completed,
          text: recoveredOutput,
          usage: runUsage,
        );
        turns[assistantIndex] = assistantTurn;
        _setTurns(sessionId, List.of(turns), clearErrorMessage: true);
        return;
      }
      if (recoveredRun?.status
          case HermesRunLifecycle.running || HermesRunLifecycle.queued) {
        _setTurns(
          sessionId,
          List.of(turns),
          errorMessage:
              'Hermes run is still active after its event stream closed. Reconnect before retrying.',
        );
        return;
      }
      try {
        final serverTurns = await _fetchTurns(client, sessionId);
        if (_serverHistoryHasAssistantReplyForCurrentTurn(
          serverTurns,
          message,
          preSendTurnCount,
        )) {
          _setTurns(sessionId, serverTurns, clearErrorMessage: true);
          return;
        }
      } catch (_) {
        // Keep the local failed partial transcript; recovery is best-effort.
      }
    }

    if (!streamFailed && !stoppedLocally) {
      try {
        final serverTurns = await _fetchTurns(client, sessionId);
        if (!_serverHistoryDropsStreamedAssistant(
          serverTurns,
          assistantTurn,
          message,
          preSendTurnCount,
        )) {
          _setTurns(
            sessionId,
            _attachUsageToLatestAssistant(
              _mergeRunDetailTurns(serverTurns, turns.skip(preSendTurnCount)),
              runUsage,
            ),
          );
        }
      } catch (_) {
        // Keep the locally streamed transcript; reconciliation is best-effort.
      }
    }
  }

  String? _streamDelta(HermesStreamEvent event) {
    if (!_isDeltaEvent(event.name)) return null;
    return _rawStreamText(event.payload['delta']) ??
        _rawStreamText(event.payload['content']) ??
        _rawStreamText(event.payload['text']);
  }

  String? _rawStreamText(Object? value) {
    if (value is String) return value.isEmpty ? null : value;
    return wingOptionalStringFromJson(value);
  }

  bool _isDeltaEvent(String name) {
    return name == 'message' ||
        name == 'message.delta' ||
        name == 'assistant.delta' ||
        name == 'response.delta' ||
        name == 'response.text.delta' ||
        name == 'response.output_text.delta';
  }

  bool _serverHistoryDropsStreamedAssistant(
    List<HermesChatTurn> serverTurns,
    HermesChatTurn localAssistantTurn,
    String sentMessage,
    int preSendTurnCount,
  ) {
    if (localAssistantTurn.text.trim().isEmpty) return false;
    return !_serverHistoryHasAssistantReplyForCurrentTurn(
      serverTurns,
      sentMessage,
      preSendTurnCount,
    );
  }

  bool _serverHistoryHasAssistantReplyForCurrentTurn(
    List<HermesChatTurn> serverTurns,
    String sentMessage,
    int preSendTurnCount,
  ) {
    final normalizedMessage = sentMessage.trim();
    if (normalizedMessage.isNotEmpty) {
      for (var index = serverTurns.length - 1; index >= 0; index--) {
        final turn = serverTurns[index];
        if (turn.author != HermesTurnAuthor.user ||
            turn.text.trim() != normalizedMessage ||
            index < preSendTurnCount) {
          continue;
        }
        return _hasAssistantReplyAfter(serverTurns, index);
      }
    }
    if (serverTurns.length <= preSendTurnCount) return false;
    return _hasAssistantReplyAfter(serverTurns, preSendTurnCount - 1);
  }

  bool _hasAssistantReplyAfter(List<HermesChatTurn> serverTurns, int index) {
    for (final candidate in serverTurns.skip(index + 1)) {
      if (candidate.author == HermesTurnAuthor.user) return false;
      if (candidate.author == HermesTurnAuthor.assistant &&
          candidate.text.trim().isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  List<HermesChatTurn> _mergeRunDetailTurns(
    List<HermesChatTurn> serverTurns,
    Iterable<HermesChatTurn> localRunTurns,
  ) {
    final details = localRunTurns
        .where((turn) => turn.kind != HermesTurnKind.text)
        .toList(growable: false);
    if (details.isEmpty) return serverTurns;
    final merged = List<HermesChatTurn>.from(serverTurns);
    final assistantIndex = merged.lastIndexWhere(
      (turn) => turn.author == HermesTurnAuthor.assistant,
    );
    merged.insertAll(
      assistantIndex < 0 ? merged.length : assistantIndex,
      details,
    );
    return merged;
  }

  List<HermesChatTurn> _attachUsageToLatestAssistant(
    List<HermesChatTurn> turns,
    HermesRunUsage? usage,
  ) {
    if (usage == null) return turns;
    final merged = List<HermesChatTurn>.from(turns);
    for (var index = merged.length - 1; index >= 0; index--) {
      final turn = merged[index];
      if (turn.author != HermesTurnAuthor.assistant ||
          turn.text.trim().isEmpty) {
        continue;
      }
      merged[index] = turn.copyWith(usage: usage);
      break;
    }
    return merged;
  }

  bool _isApprovalRequestEvent(String name) {
    return name == 'approval.request' ||
        name == 'approval.requested' ||
        name == 'approval.required';
  }

  bool _isStreamErrorEvent(String name) {
    return name == 'error' ||
        name == 'stream.error' ||
        name == 'run.error' ||
        name == 'assistant.error' ||
        name == 'message.error' ||
        name == 'response.error';
  }

  String _streamErrorMessage(HermesStreamEvent event) {
    final detail = _streamErrorDetail(event.payload);
    if (detail == null || detail.trim().isEmpty) {
      return 'Hermes stream reported an error.';
    }
    return 'Hermes stream reported an error: ${_safeHermesError(detail)}';
  }

  String? _streamErrorDetail(Map<String, Object?> payload) {
    final topLevel =
        wingOptionalStringFromJson(payload['message']) ??
        wingOptionalStringFromJson(payload['detail']);
    if (topLevel != null) return topLevel;
    final nested = wingMapFromJson(payload['error']);
    if (nested.isNotEmpty) {
      final code = wingOptionalStringFromJson(nested['code']);
      final message =
          wingOptionalStringFromJson(nested['message']) ??
          wingOptionalStringFromJson(nested['detail']);
      if (code != null && message != null) return '$code: $message';
      return message ?? code;
    }
    return wingOptionalStringFromJson(payload['error']);
  }

  bool _isSuccessfulTerminalRunEvent(String name) {
    return name == 'run.completed' ||
        name == 'assistant.completed' ||
        name == 'message.completed' ||
        name == 'response.completed' ||
        name == 'response.done';
  }

  bool _isFailedTerminalRunEvent(String name) {
    return name == 'run.failed' ||
        name == 'assistant.failed' ||
        name == 'message.failed' ||
        name == 'response.failed' ||
        _isCancelledTerminalRunEvent(name);
  }

  bool _isCancelledTerminalRunEvent(String name) {
    return name == 'run.cancelled' ||
        name == 'assistant.cancelled' ||
        name == 'message.cancelled' ||
        name == 'response.cancelled' ||
        name == 'response.canceled';
  }

  bool _applyReasoningEvent({
    required String sessionId,
    required HermesStreamEvent event,
    required List<HermesChatTurn> turns,
    required int insertBefore,
  }) {
    final rawText = wingOptionalStringFromJson(event.payload['text'])?.trim();
    if (rawText == null || rawText.isEmpty) return false;
    const maximumLength = 16384;
    final text = rawText.length <= maximumLength
        ? rawText
        : '${rawText.substring(0, maximumLength - 1)}…';
    turns.insert(
      insertBefore,
      HermesChatTurn(
        id: 'reasoning-${_activeRunId ?? sessionId}-${turns.length}',
        sessionId: sessionId,
        author: HermesTurnAuthor.system,
        createdAt: DateTime.now(),
        kind: HermesTurnKind.reasoning,
        text: text,
      ),
    );
    return true;
  }

  bool _isToolEvent(String name) {
    return name == 'tool.started' ||
        name == 'tool.progress' ||
        name == 'tool.completed' ||
        name == 'tool.failed';
  }

  /// Tracks tool progress by a `${runId}:${eventCallId}` call id when Hermes
  /// supplies one, falling back to `${runId}:${toolName}` for older events: the
  /// first event for a call id inserts a new turn just before the assistant
  /// reply; later events for the same call id update that turn in place instead
  /// of duplicating it.
  void _applyToolEvent({
    required String sessionId,
    required HermesStreamEvent event,
    required List<HermesChatTurn> turns,
    required Map<String, int> toolTurnIndexByCallId,
    required int insertBefore,
  }) {
    final toolName =
        wingOptionalStringFromJson(event.payload['tool']) ??
        wingOptionalStringFromJson(event.payload['tool_name']) ??
        'tool';
    final status = switch (event.name) {
      'tool.completed' => 'completed',
      'tool.failed' => 'failed',
      _ => 'running',
    };
    final preview = wingOptionalStringFromJson(event.payload['preview']);
    final result =
        wingOptionalStringFromJson(event.payload['result_text']) ??
        wingOptionalStringFromJson(event.payload['output']) ??
        wingOptionalStringFromJson(event.payload['result']);
    final eventCallId =
        wingOptionalStringFromJson(event.payload['tool_call_id']) ??
        wingOptionalStringFromJson(event.payload['call_id']) ??
        wingOptionalStringFromJson(event.payload['id']);
    final callId = eventCallId == null || eventCallId.trim().isEmpty
        ? '$_activeRunId:$toolName'
        : '$_activeRunId:${eventCallId.trim()}';

    final existingIndex = toolTurnIndexByCallId[callId];
    if (existingIndex != null) {
      final existing = turns[existingIndex];
      turns[existingIndex] = existing.copyWith(
        toolCall: existing.toolCall!.copyWith(
          status: status,
          preview: preview,
          result: result,
        ),
      );
      return;
    }
    final turn = HermesChatTurn(
      id: 'tool-$callId',
      sessionId: sessionId,
      author: HermesTurnAuthor.system,
      createdAt: DateTime.now(),
      kind: HermesTurnKind.toolCall,
      toolCall: HermesToolCall(
        name: toolName,
        status: status,
        preview: preview,
        result: result,
      ),
    );
    turns.insert(insertBefore, turn);
    toolTurnIndexByCallId[callId] = insertBefore;
  }

  HermesApprovalRequest _approvalRequestFromEvent(HermesStreamEvent event) {
    return HermesApprovalRequest(
      id:
          wingOptionalStringFromJson(event.payload['approval_id']) ??
          wingOptionalStringFromJson(event.payload['approvalId']) ??
          wingOptionalStringFromJson(event.payload['id']) ??
          '',
      toolCallId:
          wingOptionalStringFromJson(event.payload['tool_call_id']) ??
          wingOptionalStringFromJson(event.payload['toolCallId']) ??
          '',
      prompt:
          wingOptionalStringFromJson(event.payload['prompt']) ??
          'Approval requested',
      risk: wingOptionalStringFromJson(event.payload['risk']),
    );
  }

  void _setTurns(
    String sessionId,
    List<HermesChatTurn> turns, {
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    _setState(
      _state.copyWith(
        messages: {..._state.messages, sessionId: turns},
        errorMessage: errorMessage,
        clearErrorMessage: clearErrorMessage,
      ),
    );
  }

  void _cancelActiveTurn() {
    _finishActiveTurnLocally();
  }

  void _stopActiveTurn() {
    final client = _client;
    final runId = _activeRunId;
    _finishActiveTurnLocally();
    final capabilities = _state.capabilities;
    final canStopRun = capabilities == null
        ? true
        : HermesTransportPolicy(capabilities).supportsRunStop;
    if (client != null && runId != null && canStopRun) {
      unawaited(client.stopRun(runId).catchError((_) {}));
    }
  }

  void _finishActiveTurnLocally() {
    _activeTurnStopped = true;
    _streamGeneration += 1;
    _markActiveStreamingTurnStopped();
    unawaited(_activeStream?.cancel() ?? Future<void>.value());
    _activeStream = null;
    _activeRunId = null;
    final completer = _activeStreamCompleter;
    _activeStreamCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  void _markActiveStreamingTurnStopped() {
    final sessionId = _state.activeSessionId;
    if (sessionId == null) return;
    final turns = List<HermesChatTurn>.from(_state.activeMessages);
    final index = turns.lastIndexWhere(
      (turn) => turn.status == HermesTurnStatus.streaming,
    );
    if (index == -1) return;
    final turn = turns[index];
    turns[index] = turn.copyWith(
      status: HermesTurnStatus.failed,
      text: turn.text.isEmpty ? 'Stopped.' : turn.text,
    );
    _setTurns(sessionId, turns);
  }
}

String _escapeAttachmentXml(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');
