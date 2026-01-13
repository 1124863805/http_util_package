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

  /// 生成请求唯一ID
  String _generateRequestId(dio_package.RequestOptions options) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final hashCode = options.hashCode;
    return '${timestamp.toString().substring(timestamp.toString().length - 6)}_${hashCode.toRadixString(36)}';
  }

  /// 格式化耗时
  String _formatDuration(Duration duration) {
    if (duration.inMilliseconds < 1000) {
      return '${duration.inMilliseconds}ms';
    } else {
      return '${(duration.inMilliseconds / 1000).toStringAsFixed(2)}s';
    }
  }

  /// 打印 Headers（统一处理，确保所有 headers 都被打印）
  /// [indent] 缩进字符串，如 "│   " 或 "│      "
  /// 注意：此方法内部调用，不进行同步（由调用者负责同步）
  void _logHeadersUnsafe(Map<String, dynamic> headers,
      {String indent = '│      '}) {
    if (headers.isEmpty) return;

    print('[HttpUtil] ${indent}Headers:');
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
      print('[HttpUtil] $indent$key: $displayValue');
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
      print(
          '[HttpUtil] ┌─────────────────────────────────────────────────────────────');
      print('[HttpUtil] │ Request: ${options.method} ${options.uri}');
      _logHeadersUnsafe(options.headers, indent: '│   ');
      if (printBody && options.data != null) {
        print('[HttpUtil] │ Body:');
        print('[HttpUtil] │   ${options.data}');
      }
      if (options.queryParameters.isNotEmpty) {
        print('[HttpUtil] │ Query Parameters:');
        options.queryParameters.forEach((key, value) {
          print('[HttpUtil] │   $key: $value');
        });
      }
      print(
          '[HttpUtil] └─────────────────────────────────────────────────────────────');
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

      print(
          '[HttpUtil] ┌─────────────────────────────────────────────────────────────');
      print(
          '[HttpUtil] │ [请求链路 #$requestId] ${options.method} ${options.uri} (耗时: ${_formatDuration(duration)}) $statusIcon');
      print(
          '[HttpUtil] │ ───────────────────────────────────────────────────────────');
      print('[HttpUtil] │ 📤 Request:');
      print('[HttpUtil] │    Method: ${options.method}');
      print('[HttpUtil] │    URL: ${options.uri}');
      _logHeadersUnsafe(headers);
      if (printBody && options.data != null) {
        print('[HttpUtil] │    Body:');
        print('[HttpUtil] │      ${options.data}');
      }
      if (options.queryParameters.isNotEmpty) {
        print('[HttpUtil] │    Query Parameters:');
        options.queryParameters.forEach((key, value) {
          print('[HttpUtil] │      $key: $value');
        });
      }
      print(
          '[HttpUtil] │ ───────────────────────────────────────────────────────────');
      print('[HttpUtil] │ 📥 Response:');
      print(
          '[HttpUtil] │    Status: ${response.statusCode} ${response.statusMessage ?? ''}');
      if (printBody && response.data != null) {
        print('[HttpUtil] │    Body:');
        print('[HttpUtil] │      ${response.data}');
      }
      print(
          '[HttpUtil] └─────────────────────────────────────────────────────────────');
    });
  }

  /// 打印响应日志（实时模式使用）
  void _logResponse(dio_package.Response response) {
    _synchronizedLog(() async {
      print(
          '[HttpUtil] ┌─────────────────────────────────────────────────────────────');
      print(
          '[HttpUtil] │ Response: ${response.statusCode} ${response.statusMessage ?? ''}');
      print(
          '[HttpUtil] │ Request: ${response.requestOptions.method} ${response.requestOptions.uri}');
      if (printBody && response.data != null) {
        print('[HttpUtil] │ Body:');
        print('[HttpUtil] │   ${response.data}');
      }
      print(
          '[HttpUtil] └─────────────────────────────────────────────────────────────');
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

      print(
          '[HttpUtil] ┌─────────────────────────────────────────────────────────────');
      print(
          '[HttpUtil] │ [请求链路 #$requestId] ${options.method} ${options.uri} (耗时: ${_formatDuration(duration)}) ❌');
      print(
          '[HttpUtil] │ ───────────────────────────────────────────────────────────');
      print('[HttpUtil] │ 📤 Request:');
      print('[HttpUtil] │    Method: ${options.method}');
      print('[HttpUtil] │    URL: ${options.uri}');
      _logHeadersUnsafe(options.headers);
      if (printBody && options.data != null) {
        print('[HttpUtil] │    Body:');
        print('[HttpUtil] │      ${options.data}');
      }
      if (options.queryParameters.isNotEmpty) {
        print('[HttpUtil] │    Query Parameters:');
        options.queryParameters.forEach((key, value) {
          print('[HttpUtil] │      $key: $value');
        });
      }
      print(
          '[HttpUtil] │ ───────────────────────────────────────────────────────────');
      print('[HttpUtil] │ ❌ Error:');
      print('[HttpUtil] │    Type: ${error.type.toString()}');
      if (error.response != null) {
        final statusCode = error.response!.statusCode;
        print(
            '[HttpUtil] │    Status: $statusCode ${error.response!.statusMessage ?? ''}');
        if (printBody && error.response!.data != null) {
          print('[HttpUtil] │    Body:');
          print('[HttpUtil] │      ${error.response!.data}');
        }
      }
      if (error.message != null) {
        print('[HttpUtil] │    Message: ${error.message!}');
      }
      print(
          '[HttpUtil] └─────────────────────────────────────────────────────────────');
    });
  }

  /// 打印错误日志（实时模式使用）
  void _logError(dio_package.DioException error) {
    _synchronizedLog(() async {
      print(
          '[HttpUtil] ┌─────────────────────────────────────────────────────────────');
      print('[HttpUtil] │ Error: ${error.type.toString()}');
      print(
          '[HttpUtil] │ Request: ${error.requestOptions.method} ${error.requestOptions.uri}');
      if (error.response != null) {
        final statusCode = error.response!.statusCode;
        print(
            '[HttpUtil] │ Response: $statusCode ${error.response!.statusMessage ?? ''}');
        if (printBody && error.response!.data != null) {
          print('[HttpUtil] │ Body:');
          print('[HttpUtil] │   ${error.response!.data}');
        }
      }
      if (error.message != null) {
        print('[HttpUtil] │    Message: ${error.message!}');
      }
      print(
          '[HttpUtil] └─────────────────────────────────────────────────────────────');
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
