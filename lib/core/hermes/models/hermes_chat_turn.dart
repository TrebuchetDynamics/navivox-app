import 'hermes_tool_call.dart';

export 'hermes_tool_call.dart';

enum HermesTurnAuthor { user, assistant, system }

enum HermesTurnStatus { streaming, completed, failed }

enum HermesTurnKind { text, toolCall }

/// One turn in a Hermes session transcript. Assistant turns start
/// `streaming` and accumulate `text` via [appendDelta] as SSE deltas arrive.
/// `toolCall`-kind turns carry a [HermesToolCall] instead of prose `text`.
class HermesChatTurn {
  const HermesChatTurn({
    required this.id,
    required this.sessionId,
    required this.author,
    required this.createdAt,
    this.status = HermesTurnStatus.completed,
    this.kind = HermesTurnKind.text,
    this.text = '',
    this.toolCall,
  });

  final String id;
  final String sessionId;
  final HermesTurnAuthor author;
  final HermesTurnStatus status;
  final HermesTurnKind kind;
  final String text;
  final HermesToolCall? toolCall;
  final DateTime createdAt;

  HermesChatTurn appendDelta(String delta) => copyWith(text: text + delta);

  HermesChatTurn copyWith({
    HermesTurnStatus? status,
    String? text,
    HermesToolCall? toolCall,
  }) {
    return HermesChatTurn(
      id: id,
      sessionId: sessionId,
      author: author,
      createdAt: createdAt,
      status: status ?? this.status,
      kind: kind,
      text: text ?? this.text,
      toolCall: toolCall ?? this.toolCall,
    );
  }
}
