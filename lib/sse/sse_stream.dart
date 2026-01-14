import 'dart:async';
import 'sse_event.dart';

/// SSE 流处理类
/// 负责解析 SSE 数据流并转换为 SSEEvent
class SSEStream {
  final Stream<String> _stream;
  StreamController<SSEEvent>? _controller;
  StreamSubscription<String>? _subscription;
  Stream<SSEEvent>? _cachedStream;
  bool _isClosed = false;

  /// 当前事件数据（可能跨多行）
  String _currentData = '';

  /// 当前事件类型
  String? _currentEvent;

  /// 当前事件 ID
  String? _currentId;

  /// 当前重试间隔
  int? _currentRetry;

  SSEStream(this._stream);

  /// 获取事件流
  /// 注意：多次调用会返回同一个流对象，不会创建多个订阅
  Stream<SSEEvent> get events {
    // 如果已经创建过流，直接返回缓存的流
    if (_cachedStream != null) {
      return _cachedStream!;
    }

    _controller ??= StreamController<SSEEvent>.broadcast();
    _subscription ??= _stream.listen(
      _onData,
      onError: _onError,
      onDone: _onDone,
      cancelOnError: false,
    );

    // 缓存流对象，避免多次调用时重复创建
    _cachedStream = _controller!.stream;
    return _cachedStream!;
  }

  /// 处理接收到的数据（逐行处理）
  void _onData(String line) {
    if (_isClosed) return;

    // 空行表示一个事件的结束
    if (line.isEmpty) {
      if (_currentData.isNotEmpty) {
        _emitEvent();
      }
      return;
    }

    // 处理注释行（以 : 开头）
    if (line.startsWith(':')) {
      return;
    }

    // 解析字段
    final colonIndex = line.indexOf(':');
    if (colonIndex == -1) {
      // 没有冒号，整行作为字段名，值为空
      _processField(line, '');
    } else {
      final field = line.substring(0, colonIndex).trim();
      // 注意：SSE 规范中，如果值以空格开头，需要保留第一个空格
      // 但通常我们直接 trim，如果需要保留，可以改为：
      // final value = line.substring(colonIndex + 1);
      final value = line.substring(colonIndex + 1).trim();
      _processField(field, value);
    }
  }

  /// 处理字段
  void _processField(String field, String value) {
    switch (field) {
      case 'data':
        // 如果已有数据，追加换行符和数据
        if (_currentData.isNotEmpty) {
          _currentData += '\n$value';
        } else {
          _currentData = value;
        }
        break;
      case 'event':
        _currentEvent = value;
        break;
      case 'id':
        _currentId = value;
        break;
      case 'retry':
        try {
          _currentRetry = int.tryParse(value);
        } catch (e) {
          // 忽略解析错误
        }
        break;
    }
  }

  /// 发送事件
  void _emitEvent() {
    if (_currentData.isEmpty) return;
    // 检查 controller 是否已关闭，防止在关闭后调用 add()
    if (_isClosed || _controller == null || _controller!.isClosed) return;

    final event = SSEEvent(
      data: _currentData,
      event: _currentEvent,
      id: _currentId,
      retry: _currentRetry,
    );

    _controller!.add(event);

    // 重置状态（保留 event 和 id，因为可能用于后续事件）
    _currentData = '';
    // _currentEvent 和 _currentId 保留，因为 SSE 规范允许它们跨事件
  }

  /// 处理错误
  void _onError(Object error) {
    // 检查 controller 是否已关闭，防止在关闭后调用 addError()
    if (!_isClosed && _controller != null && !_controller!.isClosed) {
      _controller!.addError(error);
    }
  }

  /// 处理完成
  void _onDone() {
    // 发送最后一个事件（如果有未发送的数据）
    if (_currentData.isNotEmpty) {
      _emitEvent();
    }
    // 检查 controller 是否已关闭，防止重复关闭
    if (!_isClosed && _controller != null && !_controller!.isClosed) {
      _controller!.close();
      _isClosed = true;
    }
  }

  /// 关闭流
  Future<void> close() async {
    if (_isClosed) return;
    _isClosed = true;
    await _subscription?.cancel();
    // 检查 controller 是否已关闭，防止重复关闭
    if (_controller != null && !_controller!.isClosed) {
      await _controller!.close();
    }
  }
}
