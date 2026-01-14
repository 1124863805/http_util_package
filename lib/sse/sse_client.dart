import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'sse_event.dart';
import 'sse_stream.dart';

/// SSE 客户端
/// 用于建立和维护 Server-Sent Events 连接
class SSEClient {
  final String baseUrl;
  final String path;
  final Map<String, String>? queryParameters;
  final Map<String, String>? staticHeaders;
  final Future<Map<String, String>> Function()? dynamicHeaderBuilder;
  HttpClient? _httpClient;
  HttpClientRequest? _request;
  HttpClientResponse? _response;
  StreamSubscription<SSEEvent>? _subscription;
  SSEStream? _sseStream; // 保存 SSEStream 引用，以便在关闭时清理
  bool _isClosed = false;
  bool _isConnecting = false;
  bool _isConnected = false;
  final StreamController<SSEEvent> _eventController =
      StreamController<SSEEvent>.broadcast();

  SSEClient({
    required this.baseUrl,
    required this.path,
    this.queryParameters,
    this.staticHeaders,
    this.dynamicHeaderBuilder,
  });

  /// 获取事件流
  Stream<SSEEvent> get events => _eventController.stream;

  /// 连接是否已关闭
  bool get isClosed => _isClosed;

  /// 是否已连接
  bool get isConnected => _isConnected;

  /// 建立连接
  Future<void> connect() async {
    if (_isClosed) {
      throw StateError('SSE 客户端已关闭');
    }

    if (_isConnected) {
      throw StateError('SSE 客户端已经连接，请先关闭现有连接');
    }

    if (_isConnecting) {
      throw StateError('SSE 客户端正在连接中，请勿重复调用');
    }

    _isConnecting = true;

    try {
      // 构建 URL
      final uri = _buildUri();

      // 创建 HTTP 客户端
      _httpClient = HttpClient();

      // 创建请求
      _request = await _httpClient!.getUrl(uri);

      // 设置请求头（必须 await，因为动态请求头构建是异步的）
      await _setHeaders();

      // 发送请求
      _response = await _request!.close();

      // 检查响应状态
      if (_response!.statusCode != 200) {
        throw HttpException(
          'SSE 连接失败: HTTP ${_response!.statusCode}',
          uri: uri,
        );
      }

      // 检查 Content-Type
      final contentType = _response!.headers.value('content-type');
      if (contentType == null || !contentType.contains('text/event-stream')) {
        // 警告但不阻止，因为某些服务器可能不设置正确的 Content-Type
        print('警告: 响应 Content-Type 不是 text/event-stream: $contentType');
      }

      // 处理响应流
      _handleResponse();
      _isConnected = true;
    } catch (e) {
      // 连接失败时清理资源
      _cleanupResources();
      // 检查 _eventController 是否已关闭，防止在关闭后调用 addError()
      if (!_isClosed && !_eventController.isClosed) {
        _eventController.addError(e);
      }
      rethrow;
    } finally {
      _isConnecting = false;
    }
  }

  /// 清理资源（内部方法）
  /// 注意：此方法不等待异步操作完成，仅用于快速清理
  /// 如果需要完整清理，应调用 close() 方法
  void _cleanupResources() {
    // 取消订阅（不等待，因为这是快速清理）
    _subscription?.cancel();
    _subscription = null;
    // 清理 SSEStream（不等待，因为这是快速清理，但需要调用 close() 释放资源）
    _sseStream?.close();
    _sseStream = null;
    _httpClient?.close(force: true);
    _httpClient = null;
    _request = null;
    _response = null;
  }

  /// 构建 URI
  /// 使用 Uri.resolve 确保 URL 构建正确，避免双斜杠等问题
  Uri _buildUri() {
    // 解析 baseUrl
    final baseUri = Uri.parse(baseUrl);

    // 使用 resolve 方法构建完整 URL，自动处理路径拼接
    final resolvedUri = baseUri.resolve(path);

    // 合并查询参数
    final queryParams = <String, String>{};

    // 添加现有查询参数（从 resolvedUri）
    if (resolvedUri.hasQuery) {
      resolvedUri.queryParameters.forEach((key, value) {
        queryParams[key] = value;
      });
    }

    // 添加新查询参数（优先级更高，会覆盖现有参数）
    if (queryParameters != null) {
      queryParams.addAll(queryParameters!);
    }

    // 如果有查询参数，替换 URI
    if (queryParams.isNotEmpty) {
      return resolvedUri.replace(queryParameters: queryParams);
    }

    return resolvedUri;
  }

  /// 设置请求头
  Future<void> _setHeaders() async {
    if (_request == null) return;

    // 设置 SSE 必需的请求头
    _request!.headers.set('Accept', 'text/event-stream');
    _request!.headers.set('Cache-Control', 'no-cache');

    // 添加静态请求头
    if (staticHeaders != null) {
      staticHeaders!.forEach((key, value) {
        _request!.headers.set(key, value);
      });
    }

    // 添加动态请求头
    if (dynamicHeaderBuilder != null) {
      final dynamicHeaders = await dynamicHeaderBuilder!();
      dynamicHeaders.forEach((key, value) {
        _request!.headers.set(key, value);
      });
    }
  }

  /// 处理响应流
  void _handleResponse() {
    if (_response == null) return;

    // 将字节流转换为字符串流
    final stringStream =
        _response!.transform(utf8.decoder).transform(const LineSplitter());

    // 创建 SSE 流处理器（保存引用以便在关闭时清理）
    _sseStream = SSEStream(stringStream);

    // 订阅事件
    _subscription = _sseStream!.events.listen(
      (event) {
        // 检查 _eventController 是否已关闭，防止在关闭后调用 add()
        if (!_isClosed && !_eventController.isClosed) {
          _eventController.add(event);
        }
      },
      onError: (error) {
        // 检查 _eventController 是否已关闭，防止在关闭后调用 addError()
        if (!_isClosed && !_eventController.isClosed) {
          _eventController.addError(error);
        }
      },
      onDone: () {
        // 检查 _eventController 是否已关闭，防止重复关闭
        if (!_isClosed && !_eventController.isClosed) {
          _eventController.close();
          _isClosed = true;
        }
      },
    );
  }

  /// 关闭连接
  Future<void> close() async {
    if (_isClosed) return;
    _isClosed = true;
    _isConnected = false;
    _isConnecting = false;

    await _subscription?.cancel();
    _subscription = null;
    // 清理 SSEStream
    await _sseStream?.close();
    _sseStream = null;
    _httpClient?.close(force: true);
    _httpClient = null;
    _request = null;
    _response = null;
    // 检查 _eventController 是否已关闭，防止重复关闭
    if (!_eventController.isClosed) {
      await _eventController.close();
    }
  }
}
