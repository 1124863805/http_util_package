import 'package:dio/dio.dart' as dio_package;
import 'dart:async';
import 'http_config.dart';

/// 日志拦截器
/// 用于打印 HTTP 请求和响应的详细信息
class LogInterceptor extends dio_package.Interceptor {
  /// 是否打印请求/响应 body
  final bool printBody;

  /// 日志打印模式
  final LogMode logMode;

  /// 是否在请求时显示简要提示（仅在 complete 模式下有效）
  final bool showRequestHint;

  LogInterceptor({
    this.printBody = true,
    this.logMode = LogMode.complete,
    this.showRequestHint = true,
  });

  /// 日志输出锁，确保并发请求时日志不会乱序
  static Completer<void> _logLock = Completer<void>()..complete();

  /// 请求开始时间存储键
  static const String _requestStartTimeKey = '_request_start_time';
  static const String _requestIdKey = '_request_id';

  /// 串行化日志输出，确保并发请求时日志不会乱序
  /// 使用 Completer 队列来串行化所有日志输出
  Future<void> _synchronizedLog(Future<void> Function() logAction) async {
    final previous = _logLock;
    final current = Completer<void>();
    _logLock = current;

    await previous.future;
    try {
      await logAction();
    } finally {
      current.complete();
    }
  }

  /// 按行输出 StringBuffer 的内容，避免单行过长被截断
  /// 在同步块内逐行输出，确保日志块的原子性
  void _printBuffer(StringBuffer buffer) {
    final content = buffer.toString();
    final lines = content.split('\n');
    for (final line in lines) {
      if (line.isNotEmpty) {
        print(line);
      }
    }
  }

  /// 生成请求唯一ID
  String _generateRequestId(dio_package.RequestOptions options) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final hashCode = options.hashCode;
    return '${timestamp.toString().substring(timestamp.toString().length - 6)}_${hashCode.toRadixString(36)}';
  }

  /// 从响应 [Headers] 读取 `x-trace-id`（大小写不敏感，与 Dio 一致）
  String? _xTraceIdFromHeaders(dio_package.Headers headers) {
    final v = headers.value('x-trace-id');
    if (v == null) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  /// 格式化耗时
  String _formatDuration(Duration duration) {
    if (duration.inMilliseconds < 1000) {
      return '${duration.inMilliseconds}ms';
    } else {
      return '${(duration.inMilliseconds / 1000).toStringAsFixed(2)}s';
    }
  }

  /// 将 Headers 追加到 StringBuffer（统一处理，确保所有 headers 都被打印）
  /// [indent] 缩进字符串，如 "│   " 或 "│      "
  /// 注意：此方法内部调用，不进行同步（由调用者负责同步）
  void _appendHeadersToStringBuffer(
      StringBuffer buffer, Map<String, dynamic> headers,
      {String indent = '│      '}) {
    if (headers.isEmpty) return;

    buffer.writeln('[HttpUtil] ${indent}Headers:');
    // 按字母顺序排序 headers，确保输出一致
    // 注意：创建新的 Map 来避免修改原始 headers
    final headersCopy = Map<String, dynamic>.from(headers);
    final sortedHeaders = Map.fromEntries(
      headersCopy.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    sortedHeaders.forEach((key, value) {
      // 隐藏敏感信息（Authorization token）
      String displayValue = value.toString();
      if (key.toLowerCase() == 'authorization' &&
          displayValue.startsWith('Bearer ')) {
        final token = displayValue.substring(7);
        displayValue =
            'Bearer ${token.length > 20 ? '${token.substring(0, 20)}...' : token}';
      }
      buffer.writeln('[HttpUtil] $indent$key: $displayValue');
    });
  }

  @override
  void onRequest(dio_package.RequestOptions options,
      dio_package.RequestInterceptorHandler handler) {
    // 记录请求开始时间和唯一ID
    final startTime = DateTime.now();
    final requestId = _generateRequestId(options);
    options.extra[_requestStartTimeKey] = startTime;
    options.extra[_requestIdKey] = requestId;

    // 根据日志模式决定打印方式
    switch (logMode) {
      case LogMode.complete:
        // 完整链路模式：只打印简要提示（如果启用）
        if (showRequestHint) {
          _logRequestHint(options, requestId);
        }
        break;
      case LogMode.realTime:
        // 实时模式：立即打印完整请求信息
        _logRequest(options);
        break;
      case LogMode.brief:
        // 简要模式：只打印方法+URL
        _logRequestBrief(options);
        break;
    }

    handler.next(options);
  }

  @override
  void onResponse(dio_package.Response response,
      dio_package.ResponseInterceptorHandler handler) {
    // 根据日志模式决定打印方式
    switch (logMode) {
      case LogMode.complete:
        // 完整链路模式：打印完整链路（请求+响应+耗时）
        // 判断是否是错误响应（400+ 状态码）
        final isError =
            response.statusCode != null && response.statusCode! >= 400;
        _logCompleteChain(response, isError: isError);
        break;
      case LogMode.realTime:
        // 实时模式：只打印响应信息
        _logResponse(response);
        break;
      case LogMode.brief:
        // 简要模式：只打印状态码+耗时
        _logResponseBrief(response);
        break;
    }

    handler.next(response);
  }

  @override
  void onError(dio_package.DioException err,
      dio_package.ErrorInterceptorHandler handler) {
    // 根据日志模式决定打印方式
    switch (logMode) {
      case LogMode.complete:
        // 完整链路模式：打印完整链路（请求+错误+耗时）
        _logCompleteChainError(err);
        break;
      case LogMode.realTime:
        // 实时模式：只打印错误信息
        _logError(err);
        break;
      case LogMode.brief:
        // 简要模式：只打印错误类型
        _logErrorBrief(err);
        break;
    }

    handler.next(err);
  }

  /// 打印请求简要提示（完整链路模式使用）
  void _logRequestHint(dio_package.RequestOptions options, String requestId) {
    _synchronizedLog(() async {
      print('[HttpUtil] → ${options.method} ${options.uri} [$requestId]');
    });
  }

  /// 打印请求日志（实时模式使用）
  void _logRequest(dio_package.RequestOptions options) {
    _synchronizedLog(() async {
      // 使用 StringBuffer 收集所有日志内容，然后一次性输出
      final buffer = StringBuffer();

      buffer.writeln(
          '[HttpUtil] ┌─────────────────────────────────────────────────────────────');
      buffer.writeln('[HttpUtil] │ Request: ${options.method} ${options.uri}');
      _appendHeadersToStringBuffer(buffer, options.headers, indent: '│   ');
      if (printBody && options.data != null) {
        buffer.writeln('[HttpUtil] │ Body:');
        buffer.writeln('[HttpUtil] │   ${options.data}');
      }
      if (options.queryParameters.isNotEmpty) {
        buffer.writeln('[HttpUtil] │ Query Parameters:');
        options.queryParameters.forEach((key, value) {
          buffer.writeln('[HttpUtil] │   $key: $value');
        });
      }
      buffer.writeln(
          '[HttpUtil] └─────────────────────────────────────────────────────────────');

      // 按行输出所有日志内容，避免单行过长被截断
      _printBuffer(buffer);
    });
  }

  /// 打印请求简要信息（简要模式使用）
  void _logRequestBrief(dio_package.RequestOptions options) {
    _synchronizedLog(() async {
      print('[HttpUtil] → ${options.method} ${options.uri}');
    });
  }

  /// 打印完整链路（请求+响应+耗时）- 成功响应
  void _logCompleteChain(dio_package.Response response,
      {required bool isError}) {
    _synchronizedLog(() async {
      final options = response.requestOptions;
      final startTime = options.extra[_requestStartTimeKey] as DateTime?;
      final requestId = options.extra[_requestIdKey] as String? ?? 'unknown';
      final duration = startTime != null
          ? DateTime.now().difference(startTime)
          : Duration.zero;

      final statusIcon = response.statusCode != null &&
              response.statusCode! >= 200 &&
              response.statusCode! < 300
          ? '✅'
          : (response.statusCode != null && response.statusCode! >= 400
              ? '❌'
              : '⚠️');

      // 确保使用完整的 headers（包括动态添加的）
      // response.requestOptions.headers 应该包含所有 headers
      final headers = Map<String, dynamic>.from(options.headers);

      // 使用 StringBuffer 收集所有日志内容，然后一次性输出
      final buffer = StringBuffer();

      buffer.writeln(
          '[HttpUtil] ┌─────────────────────────────────────────────────────────────');
      buffer.writeln(
          '[HttpUtil] │ [请求链路 #$requestId] ${options.method} ${options.uri} (耗时: ${_formatDuration(duration)}) $statusIcon');
      buffer.writeln(
          '[HttpUtil] │ ───────────────────────────────────────────────────────────');
      buffer.writeln('[HttpUtil] │ 📤 Request:');
      buffer.writeln('[HttpUtil] │    Method: ${options.method}');
      buffer.writeln('[HttpUtil] │    URL: ${options.uri}');
      _appendHeadersToStringBuffer(buffer, headers);
      if (printBody && options.data != null) {
        buffer.writeln('[HttpUtil] │    Body:');
        buffer.writeln('[HttpUtil] │      ${options.data}');
      }
      if (options.queryParameters.isNotEmpty) {
        buffer.writeln('[HttpUtil] │    Query Parameters:');
        options.queryParameters.forEach((key, value) {
          buffer.writeln('[HttpUtil] │      $key: $value');
        });
      }
      buffer.writeln(
          '[HttpUtil] │ ───────────────────────────────────────────────────────────');
      buffer.writeln('[HttpUtil] │ 📥 Response:');
      buffer.writeln(
          '[HttpUtil] │    Status: ${response.statusCode} ${response.statusMessage ?? ''}');
      final traceId = _xTraceIdFromHeaders(response.headers);
      if (traceId != null) {
        buffer.writeln('[HttpUtil] │    x-trace-id: $traceId');
      }
      if (printBody && response.data != null) {
        buffer.writeln('[HttpUtil] │    Body:');
        buffer.writeln('[HttpUtil] │      ${response.data}');
      }
      buffer.writeln(
          '[HttpUtil] └─────────────────────────────────────────────────────────────');

      // 按行输出所有日志内容，避免单行过长被截断
      _printBuffer(buffer);
    });
  }

  /// 打印响应日志（实时模式使用）
  void _logResponse(dio_package.Response response) {
    _synchronizedLog(() async {
      // 使用 StringBuffer 收集所有日志内容，然后一次性输出
      final buffer = StringBuffer();

      buffer.writeln(
          '[HttpUtil] ┌─────────────────────────────────────────────────────────────');
      buffer.writeln(
          '[HttpUtil] │ Response: ${response.statusCode} ${response.statusMessage ?? ''}');
      final traceIdRt = _xTraceIdFromHeaders(response.headers);
      if (traceIdRt != null) {
        buffer.writeln('[HttpUtil] │ x-trace-id: $traceIdRt');
      }
      buffer.writeln(
          '[HttpUtil] │ Request: ${response.requestOptions.method} ${response.requestOptions.uri}');
      if (printBody && response.data != null) {
        buffer.writeln('[HttpUtil] │ Body:');
        buffer.writeln('[HttpUtil] │   ${response.data}');
      }
      buffer.writeln(
          '[HttpUtil] └─────────────────────────────────────────────────────────────');

      // 按行输出所有日志内容，避免单行过长被截断
      _printBuffer(buffer);
    });
  }

  /// 打印响应简要信息（简要模式使用）
  void _logResponseBrief(dio_package.Response response) {
    _synchronizedLog(() async {
      final startTime =
          response.requestOptions.extra[_requestStartTimeKey] as DateTime?;
      final duration = startTime != null
          ? DateTime.now().difference(startTime)
          : Duration.zero;

      print(
          '[HttpUtil] ← ${response.statusCode} ${response.requestOptions.uri} (${_formatDuration(duration)})');
    });
  }

  /// 打印完整链路错误（请求+错误+耗时）
  void _logCompleteChainError(dio_package.DioException error) {
    _synchronizedLog(() async {
      final options = error.requestOptions;
      final startTime = options.extra[_requestStartTimeKey] as DateTime?;
      final requestId = options.extra[_requestIdKey] as String? ?? 'unknown';
      final duration = startTime != null
          ? DateTime.now().difference(startTime)
          : Duration.zero;

      // 使用 StringBuffer 收集所有日志内容，然后一次性输出
      final buffer = StringBuffer();

      buffer.writeln(
          '[HttpUtil] ┌─────────────────────────────────────────────────────────────');
      buffer.writeln(
          '[HttpUtil] │ [请求链路 #$requestId] ${options.method} ${options.uri} (耗时: ${_formatDuration(duration)}) ❌');
      buffer.writeln(
          '[HttpUtil] │ ───────────────────────────────────────────────────────────');
      buffer.writeln('[HttpUtil] │ 📤 Request:');
      buffer.writeln('[HttpUtil] │    Method: ${options.method}');
      buffer.writeln('[HttpUtil] │    URL: ${options.uri}');
      _appendHeadersToStringBuffer(buffer, options.headers);
      if (printBody && options.data != null) {
        buffer.writeln('[HttpUtil] │    Body:');
        buffer.writeln('[HttpUtil] │      ${options.data}');
      }
      if (options.queryParameters.isNotEmpty) {
        buffer.writeln('[HttpUtil] │    Query Parameters:');
        options.queryParameters.forEach((key, value) {
          buffer.writeln('[HttpUtil] │      $key: $value');
        });
      }
      buffer.writeln(
          '[HttpUtil] │ ───────────────────────────────────────────────────────────');
      buffer.writeln('[HttpUtil] │ ❌ Error:');
      buffer.writeln('[HttpUtil] │    Type: ${error.type.toString()}');
      if (error.response != null) {
        final statusCode = error.response!.statusCode;
        buffer.writeln(
            '[HttpUtil] │    Status: $statusCode ${error.response!.statusMessage ?? ''}');
        final traceIdErr = _xTraceIdFromHeaders(error.response!.headers);
        if (traceIdErr != null) {
          buffer.writeln('[HttpUtil] │    x-trace-id: $traceIdErr');
        }
        if (printBody && error.response!.data != null) {
          buffer.writeln('[HttpUtil] │    Body:');
          buffer.writeln('[HttpUtil] │      ${error.response!.data}');
        }
      }
      if (error.message != null) {
        buffer.writeln('[HttpUtil] │    Message: ${error.message!}');
      }
      buffer.writeln(
          '[HttpUtil] └─────────────────────────────────────────────────────────────');

      // 按行输出所有日志内容，避免单行过长被截断
      _printBuffer(buffer);
    });
  }

  /// 打印错误日志（实时模式使用）
  void _logError(dio_package.DioException error) {
    _synchronizedLog(() async {
      // 使用 StringBuffer 收集所有日志内容，然后一次性输出
      final buffer = StringBuffer();

      buffer.writeln(
          '[HttpUtil] ┌─────────────────────────────────────────────────────────────');
      buffer.writeln('[HttpUtil] │ Error: ${error.type.toString()}');
      buffer.writeln(
          '[HttpUtil] │ Request: ${error.requestOptions.method} ${error.requestOptions.uri}');
      if (error.response != null) {
        final statusCode = error.response!.statusCode;
        buffer.writeln(
            '[HttpUtil] │ Response: $statusCode ${error.response!.statusMessage ?? ''}');
        final traceIdErrRt = _xTraceIdFromHeaders(error.response!.headers);
        if (traceIdErrRt != null) {
          buffer.writeln('[HttpUtil] │ x-trace-id: $traceIdErrRt');
        }
        if (printBody && error.response!.data != null) {
          buffer.writeln('[HttpUtil] │ Body:');
          buffer.writeln('[HttpUtil] │   ${error.response!.data}');
        }
      }
      if (error.message != null) {
        buffer.writeln('[HttpUtil] │    Message: ${error.message!}');
      }
      buffer.writeln(
          '[HttpUtil] └─────────────────────────────────────────────────────────────');

      // 按行输出所有日志内容，避免单行过长被截断
      _printBuffer(buffer);
    });
  }

  /// 打印错误简要信息（简要模式使用）
  void _logErrorBrief(dio_package.DioException error) {
    _synchronizedLog(() async {
      final startTime =
          error.requestOptions.extra[_requestStartTimeKey] as DateTime?;
      final duration = startTime != null
          ? DateTime.now().difference(startTime)
          : Duration.zero;

      print(
          '[HttpUtil] ✗ ${error.type.toString()} ${error.requestOptions.uri} (${_formatDuration(duration)})');
    });
  }
}
