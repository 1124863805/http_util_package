import 'dart:async';
import 'sse_event.dart';
import 'sse_client.dart';

/// SSE 连接封装类
/// 自动管理订阅和资源清理，简化使用
class SSEConnection {
  final SSEClient _client;
  StreamSubscription<SSEEvent>? _subscription;
  bool _isConnected = false;

  /// 连接状态
  bool get isConnected => _isConnected;

  /// 事件流（只读）
  Stream<SSEEvent> get events => _client.events;

  SSEConnection._(this._client);

  /// 创建并连接 SSE
  ///
  /// [baseUrl] 基础 URL
  /// [path] 请求路径
  /// [method] HTTP 方法，默认为 'GET'
  /// [data] 请求体数据（POST 请求时使用）
  /// [queryParameters] URL 查询参数
  /// [staticHeaders] 静态请求头
  /// [dynamicHeaderBuilder] 动态请求头构建器
  ///
  /// 返回已连接的 SSEConnection，可以直接监听事件
  static Future<SSEConnection> connect({
    required String baseUrl,
    required String path,
    String method = 'GET',
    dynamic data,
    Map<String, String>? queryParameters,
    Map<String, String>? staticHeaders,
    Future<Map<String, String>> Function()? dynamicHeaderBuilder,
  }) async {
    final client = SSEClient(
      baseUrl: baseUrl,
      path: path,
      method: method,
      data: data,
      queryParameters: queryParameters,
      staticHeaders: staticHeaders,
      dynamicHeaderBuilder: dynamicHeaderBuilder,
    );

    final connection = SSEConnection._(client);

    try {
      await client.connect();
      connection._isConnected = true;
    } catch (e) {
      await client.close();
      rethrow;
    }

    return connection;
  }

  /// 断开连接并清理资源
  Future<void> disconnect() async {
    if (!_isConnected) return;

    _isConnected = false;
    await _subscription?.cancel();
    _subscription = null;
    await _client.close();
  }

  /// 监听事件（自动管理订阅）
  ///
  /// [onData] 数据回调
  /// [onError] 错误回调
  /// [onDone] 完成回调
  ///
  /// 返回当前连接，支持链式调用
  SSEConnection listen({
    required void Function(SSEEvent event) onData,
    void Function(Object error)? onError,
    void Function()? onDone,
  }) {
    // 如果已有订阅，先取消
    _subscription?.cancel();

    _subscription = _client.events.listen(
      onData,
      onError: (error) {
        _isConnected = false;
        onError?.call(error);
      },
      onDone: () {
        _isConnected = false;
        onDone?.call();
      },
      cancelOnError: false,
    );

    return this;
  }

  /// 取消监听（但不断开连接）
  void cancelListen() {
    _subscription?.cancel();
    _subscription = null;
  }
}
