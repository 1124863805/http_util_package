import 'dart:async';

/// 请求队列管理器
/// 用于管理请求队列、优先级和并发数限制
class RequestQueue {
  /// 请求优先级队列（优先级高的先执行）
  /// 使用 List 存储，每次取出时排序
  final List<_QueuedRequest> _queue = [];

  /// 正在执行的请求列表
  final List<_QueuedRequest> _runningRequests = [];

  /// 最大并发数（默认 10）
  final int maxConcurrency;

  /// 是否暂停队列（暂停后不再执行新请求）
  bool _isPaused = false;

  /// 队列状态变化监听器
  final StreamController<QueueStatus> _statusController =
      StreamController<QueueStatus>.broadcast();

  RequestQueue({
    this.maxConcurrency = 10,
  });

  /// 队列状态流
  Stream<QueueStatus> get statusStream => _statusController.stream;

  /// 当前队列长度
  int get queueLength => _queue.length;

  /// 当前正在执行的请求数量
  int get runningCount => _runningRequests.length;

  /// 是否已暂停
  bool get isPaused => _isPaused;

  /// 添加请求到队列
  /// 
  /// [priority] 请求优先级（数字越大优先级越高，默认 0）
  /// [requestExecutor] 实际执行请求的函数
  /// 
  /// 返回 Future，请求完成后返回结果
  Future<T> enqueue<T>({
    int priority = 0,
    required Future<T> Function() requestExecutor,
  }) {
    final completer = Completer<T>();
    final request = _QueuedRequest<T>(
      priority: priority,
      requestExecutor: requestExecutor,
      completer: completer,
    );

    _queue.add(request);
    _notifyStatusChange();
    _processQueue();

    return completer.future;
  }

  /// 处理队列（从队列中取出请求执行）
  void _processQueue() {
    // 如果已暂停，不处理队列
    if (_isPaused) {
      return;
    }

    // 如果已达到最大并发数，不处理队列
    if (_runningRequests.length >= maxConcurrency) {
      return;
    }

    // 如果队列为空，不处理
    if (_queue.isEmpty) {
      return;
    }

    // 从队列中取出优先级最高的请求（排序后取第一个）
    _queue.sort((a, b) => b.compareTo(a)); // 优先级高的在前
    final request = _queue.removeAt(0);
    _runningRequests.add(request);

    _notifyStatusChange();

    // 执行请求
    request.execute().then((result) {
      _runningRequests.remove(request);
      _notifyStatusChange();
      _processQueue(); // 继续处理队列
    }).catchError((error) {
      _runningRequests.remove(request);
      _notifyStatusChange();
      _processQueue(); // 继续处理队列
    });
  }

  /// 暂停队列（不再执行新请求，但正在执行的请求会继续）
  void pause() {
    _isPaused = true;
    _notifyStatusChange();
  }

  /// 恢复队列（继续执行队列中的请求）
  void resume() {
    _isPaused = false;
    _notifyStatusChange();
    _processQueue();
  }

  /// 清空队列（取消所有待执行的请求）
  void clear() {
    while (_queue.isNotEmpty) {
      final request = _queue.removeAt(0);
      request.completer.completeError(
        StateError('请求队列已清空'),
      );
    }
    _notifyStatusChange();
  }

  /// 通知状态变化
  void _notifyStatusChange() {
    _statusController.add(QueueStatus(
      queueLength: _queue.length,
      runningCount: _runningRequests.length,
      isPaused: _isPaused,
    ));
  }

  /// 释放资源
  void dispose() {
    clear();
    _statusController.close();
  }
}

/// 队列中的请求
class _QueuedRequest<T> implements Comparable<_QueuedRequest> {
  final int priority;
  final Future<T> Function() requestExecutor;
  final Completer<T> completer;

  _QueuedRequest({
    required this.priority,
    required this.requestExecutor,
    required this.completer,
  });

  /// 执行请求
  Future<T> execute() async {
    try {
      final result = await requestExecutor();
      if (!completer.isCompleted) {
        completer.complete(result);
      }
      return result;
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
      rethrow;
    }
  }

  @override
  int compareTo(_QueuedRequest other) {
    // 优先级高的先执行（数字越大优先级越高）
    return other.priority.compareTo(priority);
  }
}

/// 队列状态
class QueueStatus {
  /// 队列长度
  final int queueLength;

  /// 正在执行的请求数量
  final int runningCount;

  /// 是否已暂停
  final bool isPaused;

  QueueStatus({
    required this.queueLength,
    required this.runningCount,
    required this.isPaused,
  });

  @override
  String toString() {
    return 'QueueStatus(queueLength: $queueLength, runningCount: $runningCount, isPaused: $isPaused)';
  }
}
