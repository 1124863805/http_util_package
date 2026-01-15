import 'dart:async';
import 'sse_connection.dart';
import 'sse_event.dart';

/// SSE 连接管理器
/// 用于管理多个 SSE 连接，支持同时维护多个连接
class SSEManager {
  final Map<String, SSEConnection> _connections = {};
  final Map<String, Future<void> Function()> _cancelFunctions = {};
  // 跟踪每个连接的完成状态
  final Map<String, Completer<void>> _connectionCompleters = {};

  /// 获取所有连接 ID
  List<String> get connectionIds => _connections.keys.toList();

  /// 获取连接数量
  int get connectionCount => _connections.length;

  /// 检查指定 ID 的连接是否存在
  bool hasConnection(String id) => _connections.containsKey(id);

  /// 检查指定 ID 的连接是否已连接
  bool isConnected(String id) => _connections[id]?.isConnected ?? false;

  /// 建立 SSE 连接并管理
  ///
  /// [id] 连接唯一标识符（用于管理多个连接）
  /// [path] 请求路径
  /// [method] HTTP 方法，默认为 'GET'
  /// [data] 请求体数据（POST 请求时使用）
  /// [queryParameters] URL 查询参数
  /// [headers] 特定请求的请求头（可选），会与全局请求头合并，如果键相同则覆盖全局请求头
  /// [baseUrl] 直接指定 baseUrl（最高优先级）
  /// [service] 使用 serviceBaseUrls 中定义的服务名称
  /// [onData] 数据回调
  /// [onError] 错误回调（可选）
  /// [onDone] 完成回调（可选）
  /// [replaceIfExists] 如果连接已存在，是否替换（默认 true）
  ///
  /// 返回连接 ID
  ///
  /// 示例：
  /// ```dart
  /// final manager = http.sseManager();
  ///
  /// // 建立第一个连接（使用默认 baseUrl）
  /// await manager.connect(
  ///   id: 'chat',
  ///   path: '/ai/chat/stream',
  ///   method: 'POST',
  ///   data: {'question': '你好'},
  ///   headers: {'X-Custom-Header': 'value'}, // 特定请求头
  ///   onData: (event) => print('聊天: ${event.data}'),
  /// );
  ///
  /// // 建立第二个连接（使用服务）
  /// await manager.connect(
  ///   id: 'notifications',
  ///   path: '/notifications/stream',
  ///   service: 'files', // 使用 files 服务
  ///   onData: (event) => print('通知: ${event.data}'),
  /// );
  /// ```
  Future<String> connect({
    required String id,
    required String path,
    String method = 'GET',
    dynamic data,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    String? baseUrl,
    String? service,
    required void Function(SSEEvent event) onData,
    void Function(Object error)? onError,
    void Function()? onDone,
    bool replaceIfExists = true,
  }) async {
    // 如果连接已存在
    if (_connections.containsKey(id)) {
      if (replaceIfExists) {
        // 断开旧连接
        await disconnect(id);
      } else {
        // 不替换，直接返回
        return id;
      }
    }

    // 为连接创建 Completer（用于跟踪完成状态）
    // 必须在连接建立前创建，这样即使连接在 waitForAllConnectionsDone() 调用前完成也能正确跟踪
    if (!_connectionCompleters.containsKey(id)) {
      _connectionCompleters[id] = Completer<void>();
    }

    // 子类需要实现此方法
    throw UnimplementedError('请使用 http.sseManager() 创建管理器');
  }

  /// 断开指定连接
  Future<void> disconnect(String id) async {
    final cancel = _cancelFunctions.remove(id);
    if (cancel != null) {
      await cancel();
    }
    final connection = _connections.remove(id);
    if (connection != null) {
      await connection.disconnect();
    }
    // 标记连接完成（如果还在等待列表中）
    markConnectionDone(id);
    // 清理 Completer（延迟清理，确保 waitForAllConnectionsDone() 能正确等待）
    // 注意：这里不立即清理，让 waitForAllConnectionsDone() 有机会完成
  }

  /// 断开所有连接
  Future<void> disconnectAll() async {
    final ids = _connections.keys.toList();
    for (final id in ids) {
      await disconnect(id);
    }
  }

  /// 添加连接（内部使用，子类可访问）
  void addConnection(String id, SSEConnection connection) {
    _connections[id] = connection;
  }

  /// 添加取消函数（内部使用，子类可访问）
  void addCancelFunction(String id, Future<void> Function() cancel) {
    _cancelFunctions[id] = cancel;
  }

  /// 移除连接（内部使用，子类可访问）
  void removeConnection(String id) {
    _connections.remove(id);
    _cancelFunctions.remove(id);
  }

  /// 确保连接的 Completer 存在（内部使用，子类可访问）
  /// 如果 Completer 不存在，创建一个新的
  void ensureConnectionCompleter(String id) {
    if (!_connectionCompleters.containsKey(id)) {
      _connectionCompleters[id] = Completer<void>();
    }
  }

  /// 清理所有资源
  Future<void> dispose() async {
    await disconnectAll();
  }

  /// 等待所有连接完成
  ///
  /// 返回一个 Future，当所有当前存在的连接都完成（onDone 被调用）时 resolve
  ///
  /// 注意：
  /// - 只等待调用此方法时已存在的连接
  /// - 如果在此方法调用后新增了连接，不会等待新连接
  /// - 如果所有连接都已断开，立即返回
  ///
  /// 示例：
  /// ```dart
  /// final manager = http.sseManager();
  ///
  /// // 建立多个连接
  /// await manager.connect(id: 'chat1', ...);
  /// await manager.connect(id: 'chat2', ...);
  /// await manager.connect(id: 'chat3', ...);
  ///
  /// // 等待所有连接完成
  /// await manager.waitForAllConnectionsDone();
  /// print('所有连接都已完成');
  /// ```
  Future<void> waitForAllConnectionsDone() async {
    // 如果没有连接，立即返回
    if (_connections.isEmpty) {
      return;
    }

    // 获取当前所有连接的 ID（快照，避免在等待过程中连接变化）
    final connectionIds = _connections.keys.toList();

    // 为每个连接创建 Completer（如果还没有）
    // 注意：正常情况下，Completer 应该在 connect() 时创建
    // 这里只是防御性处理，确保每个连接都有 Completer
    for (final id in connectionIds) {
      if (!_connectionCompleters.containsKey(id)) {
        // 如果 Completer 不存在，创建一个新的
        // 注意：如果连接已经完成，markConnectionDone 应该已经创建并完成了 Completer
        // 但为了防御性处理，这里也创建一个（如果连接已完成，会在 Future.wait() 中立即返回）
        _connectionCompleters[id] = Completer<void>();
      }
    }

    try {
      // 等待所有连接完成
      await Future.wait(
        connectionIds.map((id) {
          final completer = _connectionCompleters[id];
          if (completer == null) {
            // 防御性处理：如果 Completer 不存在，返回已完成的 Future
            return Future<void>.value();
          }
          return completer.future;
        }),
      );
    } finally {
      // 等待完成后，清理这些连接的 Completer
      _cleanupConnectionCompleters(connectionIds);
    }
  }

  /// 标记连接完成（内部使用，子类可访问）
  void markConnectionDone(String id) {
    var completer = _connectionCompleters[id];

    // 如果 Completer 不存在，创建一个并立即完成它
    // 这样即使 waitForAllConnectionsDone() 在连接完成后才调用，也能正确等待
    if (completer == null) {
      completer = Completer<void>();
      completer.complete();
      _connectionCompleters[id] = completer;
      return;
    }

    // Completer 已存在，如果未完成则完成它
    if (!completer.isCompleted) {
      completer.complete();
    }
    // 注意：不立即移除 Completer，保留它直到 waitForAllConnectionsDone() 完成
    // 这样即使 waitForAllConnectionsDone() 在连接完成后才调用，也能正确等待
  }

  /// 清理连接的 Completer（内部使用，在 waitForAllConnectionsDone() 完成后调用）
  void _cleanupConnectionCompleters(List<String> connectionIds) {
    for (final id in connectionIds) {
      _connectionCompleters.remove(id);
    }
  }
}
