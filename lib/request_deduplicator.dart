import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// 请求去重/防抖管理器
/// 用于防止相同请求并发发送多次
class RequestDeduplicator {
  /// 正在进行的请求缓存（key: 请求唯一标识，value: Future）
  final Map<String, Future<dynamic>> _pendingRequests = {};

  /// 防抖定时器（key: 请求唯一标识，value: Timer）
  final Map<String, Timer> _debounceTimers = {};

  /// 节流时间戳（key: 请求唯一标识，value: 上次执行时间）
  final Map<String, DateTime> _throttleTimestamps = {};

  /// 请求去重模式
  final DeduplicationMode mode;

  /// 防抖延迟时间（仅在 debounce 模式下有效）
  final Duration debounceDelay;

  /// 节流间隔时间（仅在 throttle 模式下有效）
  final Duration throttleInterval;

  RequestDeduplicator({
    this.mode = DeduplicationMode.deduplication,
    this.debounceDelay = const Duration(milliseconds: 300),
    this.throttleInterval = const Duration(milliseconds: 300),
  });

  /// 生成请求唯一标识
  /// 基于 method + baseUrl + path + queryParameters + data 生成哈希值
  static String _generateRequestKey({
    required String method,
    required String path,
    Map<String, dynamic>? queryParameters,
    dynamic data,
    String? baseUrl,
  }) {
    final buffer = StringBuffer();
    buffer.write(method.toUpperCase());
    buffer.write('|');
    // 如果提供了 baseUrl，包含在 key 中（用于区分不同服务）
    if (baseUrl != null && baseUrl.isNotEmpty) {
      buffer.write(baseUrl);
      buffer.write('|');
    }
    buffer.write(path);
    buffer.write('|');

    // 添加查询参数（排序后序列化）
    if (queryParameters != null && queryParameters.isNotEmpty) {
      final sortedKeys = queryParameters.keys.toList()..sort();
      for (final key in sortedKeys) {
        buffer.write('$key=${queryParameters[key]}&');
      }
    }

    // 添加请求体数据
    if (data != null) {
      try {
        if (data is Map || data is List) {
          buffer.write(jsonEncode(data));
        } else {
          buffer.write(data.toString());
        }
      } catch (e) {
        buffer.write(data.toString());
      }
    }

    // 生成 MD5 哈希
    final bytes = utf8.encode(buffer.toString());
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// 执行请求（带去重/防抖/节流）
  /// 
  /// [method] HTTP 方法
  /// [path] 请求路径
  /// [queryParameters] 查询参数
  /// [data] 请求体数据
  /// [baseUrl] 可选的 baseUrl（用于去重时区分不同服务）
  /// [requestExecutor] 实际执行请求的函数
  /// 
  /// 返回 Future，相同请求会共享同一个 Future
  Future<T> execute<T>({
    required String method,
    required String path,
    Map<String, dynamic>? queryParameters,
    dynamic data,
    String? baseUrl,
    required Future<T> Function() requestExecutor,
  }) async {
    final requestKey = _generateRequestKey(
      method: method,
      path: path,
      queryParameters: queryParameters,
      data: data,
      baseUrl: baseUrl,
    );

    switch (mode) {
      case DeduplicationMode.deduplication:
        return _executeWithDeduplication<T>(requestKey, requestExecutor);

      case DeduplicationMode.debounce:
        return _executeWithDebounce<T>(requestKey, requestExecutor);

      case DeduplicationMode.throttle:
        return _executeWithThrottle<T>(requestKey, requestExecutor);

      case DeduplicationMode.none:
        return requestExecutor();
    }
  }

  /// 去重模式：相同请求共享同一个 Future
  Future<T> _executeWithDeduplication<T>(
    String requestKey,
    Future<T> Function() requestExecutor,
  ) async {
    // 如果请求已存在，返回同一个 Future
    if (_pendingRequests.containsKey(requestKey)) {
      return _pendingRequests[requestKey] as Future<T>;
    }

    // 创建新的请求 Future
    final future = requestExecutor().whenComplete(() {
      // 请求完成后，从缓存中移除
      _pendingRequests.remove(requestKey);
    });

    // 缓存请求 Future
    _pendingRequests[requestKey] = future;

    return future;
  }

  /// 防抖模式：延迟执行，如果在延迟期间有新请求，取消旧请求，执行新请求
  Future<T> _executeWithDebounce<T>(
    String requestKey,
    Future<T> Function() requestExecutor,
  ) async {
    // 取消之前的定时器
    _debounceTimers[requestKey]?.cancel();

    // 创建 Completer 用于返回结果
    final completer = Completer<T>();

    // 创建新的定时器
    final timer = Timer(debounceDelay, () async {
      try {
        final result = await requestExecutor();
        if (!completer.isCompleted) {
          completer.complete(result);
        }
      } catch (e) {
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      } finally {
        _debounceTimers.remove(requestKey);
      }
    });

    _debounceTimers[requestKey] = timer;

    return completer.future;
  }

  /// 节流模式：在指定时间内只执行一次
  Future<T> _executeWithThrottle<T>(
    String requestKey,
    Future<T> Function() requestExecutor,
  ) async {
    final now = DateTime.now();
    final lastExecution = _throttleTimestamps[requestKey];

    // 如果距离上次执行时间小于节流间隔，返回上次的结果（如果有）
    if (lastExecution != null &&
        now.difference(lastExecution) < throttleInterval) {
      // 如果有正在进行的请求，返回它
      if (_pendingRequests.containsKey(requestKey)) {
        return _pendingRequests[requestKey] as Future<T>;
      }
      // 否则，等待节流间隔后执行
      await Future.delayed(
        throttleInterval - now.difference(lastExecution),
      );
    }

    // 更新执行时间戳
    _throttleTimestamps[requestKey] = DateTime.now();

    // 如果请求已存在，返回同一个 Future
    if (_pendingRequests.containsKey(requestKey)) {
      return _pendingRequests[requestKey] as Future<T>;
    }

    // 创建新的请求 Future
    final future = requestExecutor().whenComplete(() {
      // 请求完成后，从缓存中移除
      _pendingRequests.remove(requestKey);
    });

    // 缓存请求 Future
    _pendingRequests[requestKey] = future;

    return future;
  }

  /// 清除所有缓存
  void clear() {
    _pendingRequests.clear();
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    _throttleTimestamps.clear();
  }

  /// 清除指定请求的缓存
  void clearRequest({
    required String method,
    required String path,
    Map<String, dynamic>? queryParameters,
    dynamic data,
  }) {
    final requestKey = _generateRequestKey(
      method: method,
      path: path,
      queryParameters: queryParameters,
      data: data,
    );

    _pendingRequests.remove(requestKey);
    _debounceTimers[requestKey]?.cancel();
    _debounceTimers.remove(requestKey);
    _throttleTimestamps.remove(requestKey);
  }

  /// 获取当前正在进行的请求数量
  int get pendingCount => _pendingRequests.length;
}

/// 请求去重模式
enum DeduplicationMode {
  /// 去重模式：相同请求共享同一个 Future
  deduplication,

  /// 防抖模式：延迟执行，如果在延迟期间有新请求，取消旧请求，执行新请求
  debounce,

  /// 节流模式：在指定时间内只执行一次
  throttle,

  /// 无去重：正常执行所有请求
  none,
}
