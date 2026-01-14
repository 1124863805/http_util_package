/// Server-Sent Events (SSE) 事件模型
class SSEEvent {
  /// 事件数据
  final String data;

  /// 事件类型（可选）
  final String? event;

  /// 事件 ID（可选，用于重连时指定最后接收的事件）
  final String? id;

  /// 重试间隔（毫秒，可选）
  final int? retry;

  SSEEvent({
    required this.data,
    this.event,
    this.id,
    this.retry,
  });

  @override
  String toString() {
    return 'SSEEvent(event: $event, id: $id, data: $data)';
  }
}
