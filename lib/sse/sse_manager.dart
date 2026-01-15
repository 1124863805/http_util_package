import 'dart:async';
import 'sse_connection.dart';
import 'sse_event.dart';

/// SSE 连接管理器
/// 用于管理多个 SSE 连接，支持同时维护多个连接
class SSEManager {
  final Map<String, SSEConnection> _connections = {};
  final Map<String, Future<void> Function()> _cancelFunctions = {};

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

  /// 清理所有资源
  Future<void> dispose() async {
    await disconnectAll();
  }
}
