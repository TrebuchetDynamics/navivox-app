/// Progress of a single tool invocation surfaced by a Hermes run
/// (`tool.started`/`tool.completed`/`tool.failed` run events). `status` is
/// one of `running`, `completed`, `failed`.
class HermesToolCall {
  const HermesToolCall({
    required this.name,
    required this.status,
    this.preview,
    this.result,
  });

  final String name;
  final String status;
  final String? preview;
  final String? result;

  HermesToolCall copyWith({String? status, String? preview, String? result}) {
    return HermesToolCall(
      name: name,
      status: status ?? this.status,
      preview: preview ?? this.preview,
      result: result ?? this.result,
    );
  }
}
