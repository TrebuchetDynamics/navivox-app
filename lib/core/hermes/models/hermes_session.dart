import '../../protocol/navivox_json.dart';

class HermesSession {
  const HermesSession({
    required this.id,
    required this.source,
    this.model,
    this.title,
    this.messageCount = 0,
    this.lastActive,
    this.preview,
    this.parentSessionId,
  });

  factory HermesSession.fromJson(Map<String, Object?> json) {
    return HermesSession(
      id: navivoxStringFieldFromJson(json, 'id'),
      source: navivoxStringFromJson(json['source'], fallback: 'api_server'),
      model: navivoxOptionalStringFromJson(json['model']),
      title: navivoxOptionalStringFromJson(json['title']),
      messageCount: navivoxIntFromJson(json['message_count']),
      lastActive: navivoxOptionalStringFromJson(json['last_active']),
      preview: navivoxOptionalStringFromJson(json['preview']),
      parentSessionId: navivoxOptionalStringFromJson(json['parent_session_id']),
    );
  }

  final String id;
  final String source;
  final String? model;
  final String? title;
  final int messageCount;
  final String? lastActive;
  final String? preview;
  final String? parentSessionId;
}

class HermesMessage {
  const HermesMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    this.toolName,
    this.timestamp,
    this.finishReason,
  });

  factory HermesMessage.fromJson(Map<String, Object?> json) {
    return HermesMessage(
      id: navivoxStringFieldFromJson(json, 'id'),
      sessionId: navivoxStringFieldFromJson(json, 'session_id'),
      role: navivoxStringFromJson(json['role'], fallback: ''),
      content: navivoxStringFromJson(json['content'], fallback: ''),
      toolName: navivoxOptionalStringFromJson(json['tool_name']),
      timestamp: navivoxOptionalStringFromJson(json['timestamp']),
      finishReason: navivoxOptionalStringFromJson(json['finish_reason']),
    );
  }

  final String id;
  final String sessionId;
  final String role;
  final String content;
  final String? toolName;
  final String? timestamp;
  final String? finishReason;
}
