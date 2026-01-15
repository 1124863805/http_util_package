import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart' as dio_package;
import 'http_config.dart';
import 'response.dart';
import 'http_method.dart';
import 'log_interceptor.dart';
import 'simple_error_response.dart';
import 'api_response.dart';
import 'upload_file.dart';
import 'download_response.dart';
import 'sse/sse_event.dart';
import 'sse/sse_connection.dart';
import 'sse/sse_manager.dart';
import 'widgets/loading_widget.dart';
import 'request_deduplicator.dart';
import 'request_queue.dart';

/// HTTP 请求工具类
/// 基于 Dio 封装，支持配置化的请求头注入
class HttpUtil {
  HttpUtil._();

  static HttpUtil? _instance;
  static dio_package.Dio? _dioInstance;
  static HttpConfig? _config;

  /// 维护加载提示的映射（loadingId -> OverlayEntry）
  static final Map<String, OverlayEntry> _loadingOverlays = {};

  /// 链式调用的加载提示 ID（用于整个链路共享一个加载提示）
  static String? _chainLoadingId;

  /// 请求去重/防抖管理器
  static RequestDeduplicator? _deduplicator;

  /// 请求队列管理器
  static RequestQueue? _requestQueue;

  /// 获取请求队列管理器（如果已配置）
  static RequestQueue? get requestQueue => _requestQueue;

  /// 错误处理时间戳记录（key: 错误码，value: 处理时间）
  /// 用于错误去重，避免相同错误码在时间窗口内重复处理
  static final Map<int, DateTime> _errorHandledTimestamps = {};

  /// 单例获取
  static HttpUtil get instance {
    _instance ??= HttpUtil._();
    return _instance!;
  }

  /// 配置 HTTP 工具类（必须在首次使用前调用）
  static void configure(HttpConfig config) {
    _config = config;
    // 重置 Dio 实例，以便应用新配置
    _dioInstance = null;

    // 初始化请求去重/防抖管理器
    if (config.deduplicationConfig != null) {
      _deduplicator = RequestDeduplicator(
        mode: config.deduplicationConfig!.mode,
        debounceDelay: config.deduplicationConfig!.debounceDelay,
        throttleInterval: config.deduplicationConfig!.throttleInterval,
      );
    } else {
      _deduplicator = null;
    }

    // 初始化请求队列管理器
    if (config.queueConfig != null && config.queueConfig!.enabled) {
      _requestQueue = RequestQueue(
        maxConcurrency: config.queueConfig!.maxConcurrency,
      );
    } else {
      _requestQueue = null;
    }
  }

  /// 获取 Dio 实例（公开访问，方便特殊处理）
  /// 注意：使用前必须先调用 configure() 进行配置
  ///
  /// 注意：由于 Dart 的单线程模型，这里不会有真正的竞态条件
  /// 但为了代码清晰，我们使用双重检查模式
  static dio_package.Dio get dio {
    // 双重检查，确保线程安全（虽然 Dart 单线程，但为了代码清晰）
    if (_dioInstance == null) {
      if (_config == null) {
        throw StateError('HttpUtil 未配置，请先调用 HttpUtil.configure() 进行配置');
      }

      // 再次检查，防止在检查后、赋值前配置被修改（虽然不太可能）
      if (_dioInstance == null) {
        _dioInstance = dio_package.Dio();
        _dioInstance!.options = dio_package.BaseOptions(
          baseUrl: _config!.baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
          // 所有状态码都认为是有效的，不自动抛出异常
          validateStatus: (status) => true,
        );

        // 先添加请求拦截器，自动添加请求头（必须在日志拦截器之前）
        _dioInstance!.interceptors.add(
          dio_package.InterceptorsWrapper(
            onRequest: (options, handler) async {
              // 保存特定请求的请求头（通过 options.headers 传递的，优先级最高）
              final specificHeaders =
                  Map<String, dynamic>.from(options.headers);

              // 先添加静态请求头（优先级最低）
              if (_config!.staticHeaders != null) {
                options.headers.addAll(_config!.staticHeaders!);
              }

              // 再添加动态请求头（优先级中等）
              if (_config!.dynamicHeaderBuilder != null) {
                final dynamicHeaders = await _config!.dynamicHeaderBuilder!();
                options.headers.addAll(dynamicHeaders);
              }

              // 最后添加特定请求头（优先级最高，会覆盖全局请求头）
              options.headers.addAll(specificHeaders);

              return handler.next(options);
            },
            onResponse: (response, handler) {
              // 处理 401 错误（未授权）
              // 注意：这里不直接清除登录信息，而是通过回调通知外部
              // 外部可以通过 dynamicHeaderBuilder 返回空的 Authorization 来实现清除
              return handler.next(response);
            },
            onError: (error, handler) {
              // 只处理网络错误等其他错误，HTTP 错误状态码已经在 onResponse 中处理
              return handler.next(error);
            },
          ),
        );

        // 后添加日志拦截器（这样可以看到完整的 headers）
        if (_config!.enableLogging) {
          _dioInstance!.interceptors.add(
            LogInterceptor(
              printBody: _config!.logPrintBody,
              logMode: _config!.logMode,
              showRequestHint: _config!.logShowRequestHint,
            ),
          );
        }
      }
    }
    return _dioInstance!;
  }

  /// 创建独立的 Dio 实例（不依赖当前配置）
  /// 适用于需要自定义 baseUrl 或不需要拦截器的场景
  ///
  /// 示例：
  /// ```dart
  /// final customDio = HttpUtil.createDio();
  /// customDio.options.baseUrl = 'https://other-api.com';
  /// final response = await customDio.get('/endpoint');
  /// ```
  static dio_package.Dio createDio({
    String? baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
  }) {
    final dio = dio_package.Dio();
    dio.options = dio_package.BaseOptions(
      baseUrl: baseUrl ?? '',
      connectTimeout: connectTimeout ?? const Duration(seconds: 30),
      receiveTimeout: receiveTimeout ?? const Duration(seconds: 30),
      sendTimeout: sendTimeout ?? const Duration(seconds: 30),
      validateStatus: (status) => true,
    );
    return dio;
  }

  /// 请求方法（返回 Dio Response）
  /// [method] 请求方式：必须使用 hm.get、hm.post 等常量
  /// [baseUrl] 可选的 baseUrl，如果提供则覆盖默认 baseUrl
  Future<dio_package.Response> request<T>({
    required String method,
    required String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    dio_package.Options? options,
    dio_package.CancelToken? cancelToken,
    dio_package.ProgressCallback? onSendProgress,
    dio_package.ProgressCallback? onReceiveProgress,
    String? baseUrl,
  }) async {
    final upperMethod = method.toUpperCase();

    // 如果提供了 baseUrl，需要构建完整 URL 或使用独立的 Dio 实例
    final dioInstance = baseUrl != null ? _getDioForBaseUrl(baseUrl) : dio;

    switch (upperMethod) {
      case hm.get:
        return dioInstance.get<T>(
          path,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
          onReceiveProgress: onReceiveProgress,
        );
      case hm.post:
        return dioInstance.post<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
          onSendProgress: onSendProgress,
          onReceiveProgress: onReceiveProgress,
        );
      case hm.put:
        return dioInstance.put<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
          onSendProgress: onSendProgress,
          onReceiveProgress: onReceiveProgress,
        );
      case hm.delete:
        return dioInstance.delete<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
        );
      case hm.patch:
        return dioInstance.patch<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
          onSendProgress: onSendProgress,
          onReceiveProgress: onReceiveProgress,
        );
      default:
        throw ArgumentError('不支持的请求方式: $method，请使用 hm 常量（hm.get、hm.post 等）');
    }
  }

  /// 获取指定 baseUrl 的 Dio 实例
  /// 如果 baseUrl 与默认 baseUrl 相同，返回默认实例
  /// 否则创建或返回缓存的独立实例
  static final Map<String, dio_package.Dio> _dioInstances = {};

  dio_package.Dio _getDioForBaseUrl(String baseUrl) {
    // 如果与默认 baseUrl 相同，使用默认实例
    final currentConfig = _config;
    if (currentConfig != null && baseUrl == currentConfig.baseUrl) {
      return dio;
    }

    // 检查缓存
    if (_dioInstances.containsKey(baseUrl)) {
      return _dioInstances[baseUrl]!;
    }

    // 创建新实例（复用拦截器配置）
    final newDio = dio_package.Dio();
    newDio.options = dio_package.BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      validateStatus: (status) => true,
    );

    // 复制拦截器（请求头、日志等）
    if (currentConfig != null) {
      // 添加请求拦截器（自动添加请求头）
      newDio.interceptors.add(
        dio_package.InterceptorsWrapper(
          onRequest: (options, handler) async {
            // 保存特定请求的请求头（通过 options.headers 传递的，优先级最高）
            final specificHeaders = Map<String, dynamic>.from(options.headers);

            // 先添加静态请求头（优先级最低）
            if (currentConfig.staticHeaders != null) {
              options.headers.addAll(currentConfig.staticHeaders!);
            }

            // 再添加动态请求头（优先级中等）
            if (currentConfig.dynamicHeaderBuilder != null) {
              final dynamicHeaders =
                  await currentConfig.dynamicHeaderBuilder!();
              options.headers.addAll(dynamicHeaders);
            }

            // 最后添加特定请求头（优先级最高，会覆盖全局请求头）
            options.headers.addAll(specificHeaders);

            handler.next(options);
          },
        ),
      );

      // 添加日志拦截器（如果启用）
      if (currentConfig.enableLogging) {
        newDio.interceptors.add(LogInterceptor(
          printBody: currentConfig.logPrintBody,
          logMode: currentConfig.logMode,
          showRequestHint: currentConfig.logShowRequestHint,
        ));
      }
    }

    // 缓存实例
    _dioInstances[baseUrl] = newDio;
    return newDio;
  }
}

/// HttpUtil 扩展方法
/// 提供安全调用方法，自动处理异常和错误提示
extension HttpUtilSafeCall on HttpUtil {
  /// 解析 baseUrl（优先级从高到低）
  /// 1. 直接指定的 baseUrl
  /// 2. 使用服务名称从 serviceBaseUrls 中查找
  /// 3. 默认 baseUrl
  static String _resolveBaseUrl(String? baseUrl, String? service) {
    // 优先级 1: 直接指定的 baseUrl
    if (baseUrl != null && baseUrl.isNotEmpty) {
      return baseUrl;
    }

    // 优先级 2: 使用服务名称
    if (service != null && service.isNotEmpty) {
      final config = HttpUtil._config;
      if (config?.serviceBaseUrls != null) {
        final serviceBaseUrl = config!.serviceBaseUrls![service];
        if (serviceBaseUrl != null) {
          return serviceBaseUrl;
        }
        throw ArgumentError('服务 "$service" 未在 serviceBaseUrls 中定义');
      }
      throw StateError('未配置 serviceBaseUrls，无法使用服务 "$service"');
    }

    // 优先级 3: 默认 baseUrl
    final config = HttpUtil._config;
    if (config == null) {
      throw StateError('HttpUtil 未配置，请先调用 HttpUtil.configure() 进行配置');
    }
    return config.baseUrl;
  }

  /// 关闭链式调用的加载提示（供 response.dart 使用）
  static void closeChainLoading() {
    if (HttpUtil._chainLoadingId != null) {
      final loadingId = HttpUtil._chainLoadingId;
      HttpUtil._chainLoadingId = null;
      final overlayEntry = HttpUtil._loadingOverlays.remove(loadingId);
      overlayEntry?.remove();
    }
  }

  /// 检查是否已有链式调用的加载提示（供 response.dart 使用）
  static bool hasChainLoading() {
    return HttpUtil._chainLoadingId != null;
  }

  /// 获取配置（内部使用）
  static HttpConfig? get _config => HttpUtil._config;

  /// 检查错误是否应该被处理（去重检查）
  /// 
  /// [httpStatusCode] HTTP 状态码
  /// [window] 去重时间窗口
  /// 
  /// 返回 true 表示应该处理，false 表示在时间窗口内已处理过，应该跳过
  static bool _shouldHandleError(int? httpStatusCode, Duration window) {
    if (httpStatusCode == null) return true;

    final now = DateTime.now();
    final lastHandled = HttpUtil._errorHandledTimestamps[httpStatusCode];

    if (lastHandled == null || now.difference(lastHandled) >= window) {
      HttpUtil._errorHandledTimestamps[httpStatusCode] = now;
      return true;
    }

    return false; // 在时间窗口内，跳过处理
  }

  /// 清除错误处理记录（用于测试或特殊场景）
  static void clearErrorHandledRecords() {
    HttpUtil._errorHandledTimestamps.clear();
  }

  /// 处理网络错误（统一提示）
  /// 返回一个表示网络错误的 Response
  /// 注意：这里返回的 Response 需要由用户通过 ResponseParser 定义
  /// 但为了错误处理，我们创建一个简单的错误 Response
  Response<T> _handleNetworkError<T>() {
    final config = _config;
    final errorMessage = config?.networkErrorKey ?? '网络错误，请稍后重试！';

    // 网络错误没有 httpStatusCode 和 errorCode，直接调用 onFailure
    if (config?.onFailure != null) {
      config!.onFailure!(null, null, errorMessage);
    }

    // 返回一个简单的错误 Response
    // 用户应该在自己的 ResponseParser 中处理网络错误，这里只是兜底
    return SimpleErrorResponse<T>(errorMessage);
  }

  /// 显示加载提示
  /// [context] BuildContext
  /// [config] HttpConfig 配置
  /// 返回加载提示的 ID（用于关闭时使用）
  /// 如果无法找到 Overlay，返回 null（静默失败）
  String? _showLoading(BuildContext context, HttpConfig config) {
    try {
      // 优先使用用户自定义的 Widget
      Widget loadingWidget;
      if (config.loadingWidgetBuilder != null) {
        loadingWidget = config.loadingWidgetBuilder!(context);
      } else {
        // 使用默认实现
        loadingWidget = const DefaultLoadingWidget();
      }

      final overlayEntry = OverlayEntry(
        builder: (context) => loadingWidget,
      );

      // 通过 Navigator 查找根 Overlay
      final navigator = Navigator.of(context, rootNavigator: true);
      final overlay = navigator.overlay;

      if (overlay == null) {
        throw StateError('无法找到 Overlay');
      }

      overlay.insert(overlayEntry);

      final loadingId = overlayEntry.hashCode.toString();
      HttpUtil._loadingOverlays[loadingId] = overlayEntry;

      return loadingId;
    } catch (e) {
      // 如果找不到 Overlay（例如应用还未完全初始化），静默失败
      // 不显示加载提示，但不影响请求的正常执行
      return null;
    }
  }

  /// 隐藏加载提示
  /// [loadingId] 由 _showLoading 返回的 ID
  void _hideLoading(String? loadingId) {
    if (loadingId != null) {
      final overlayEntry = HttpUtil._loadingOverlays.remove(loadingId);
      overlayEntry?.remove();
    }
  }

  /// 发送请求（自动处理异常，失败时自动提示）
  /// [method] 请求方式：必须使用 hm.get、hm.post 等常量
  /// [isLoading] 是否显示加载提示（默认 false）
  /// 如果为 true 且配置了 contextGetter，将自动显示加载提示
  /// [headers] 特定请求的请求头（可选），会与全局请求头合并，如果键相同则覆盖全局请求头
  ///
  /// **链式调用中的加载提示**：
  /// 推荐使用 `http.isLoading.send()` 来明确标记链式调用，整个链路共享一个加载提示
  /// 加载提示会在整个链路结束时（成功或失败）自动关闭
  ///
  /// **请求头优先级**：
  /// 1. 特定请求的 headers（最高优先级，会覆盖全局请求头）
  /// 2. 动态请求头（dynamicHeaderBuilder）
  /// 3. 静态请求头（staticHeaders）
  ///
  /// 示例（链式调用，推荐方式）：
  /// ```dart
  /// final result = await http.isLoading
  ///   .send(
  ///     method: hm.post,
  ///     path: '/uploader/generate',
  ///     data: {'ext': 'jpg'},
  ///   )
  ///   .extractModel<FileUploadResult>(FileUploadResult.fromConfigJson)
  ///   .thenWith((uploadResult) => http.uploadToUrlResponse(...));
  /// ```
  ///
  /// 示例（单次请求）：
  /// ```dart
  /// final response = await http.send(
  ///   method: hm.post,
  ///   path: '/auth/login',
  ///   isLoading: true, // 单次请求，请求完成后自动关闭 loading
  /// );
  /// ```
  ///
  /// 示例（特定请求头）：
  /// ```dart
  /// // 某个接口需要特定的请求头
  /// final response = await http.send(
  ///   method: hm.post,
  ///   path: '/special-endpoint',
  ///   data: {'key': 'value'},
  ///   headers: {'X-Custom-Header': 'custom-value'}, // 特定请求头，会覆盖全局同名请求头
  /// );
  /// ```
  ///
  /// 示例（多服务支持）：
  /// ```dart
  /// // 配置
  /// HttpUtil.configure(
  ///   HttpConfig(
  ///     baseUrl: 'https://api.example.com/v1',
  ///     serviceBaseUrls: {
  ///       'files': 'https://files.example.com',
  ///       'cdn': 'https://cdn.example.com',
  ///     },
  ///   ),
  /// );
  ///
  /// // 使用默认 baseUrl
  /// await http.send(method: hm.get, path: '/users');
  ///
  /// // 使用服务
  /// await http.send(method: hm.post, path: '/upload', service: 'files');
  ///
  /// // 直接指定 baseUrl（最高优先级）
  /// await http.send(
  ///   method: hm.get,
  ///   path: '/data',
  ///   baseUrl: 'https://custom.example.com',
  /// );
  /// ```
  Future<Response<T>> send<T>({
    required String method,
    required String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool isLoading = false,
    Map<String, String>? headers,
    int priority = 0,
    bool skipDeduplication = false,
    bool skipQueue = false,
    String? baseUrl, // 直接指定 baseUrl（最高优先级）
    String? service, // 使用 serviceBaseUrls 中定义的服务名称
    bool isChainCall = false, // 内部参数：标记是否为链式调用（由 isLoading getter 使用）
  }) async {
    // 实际执行请求的函数
    Future<Response<T>> executeRequest() async {
      String? loadingId;
      bool isChainCallFlag = isChainCall; // 使用参数传入的 isChainCall

      // 如果需要显示加载提示
      if (isLoading) {
        final config = _config;
        if (config?.contextGetter != null) {
          final context = config!.contextGetter!();
          if (context != null) {
            // 检查是否已有链式调用的加载提示
            if (HttpUtil._chainLoadingId != null) {
              // 链式调用中已有加载提示，复用现有的
              loadingId = HttpUtil._chainLoadingId;
              isChainCallFlag = true;
            } else {
              // 创建新的加载提示
              loadingId = _showLoading(context, config);
              if (loadingId != null) {
                HttpUtil._chainLoadingId = loadingId;
                // 如果通过 isLoading getter 调用，isChainCall 参数为 true
                // 如果是单次请求，isChainCall 参数为 false
                isChainCallFlag = isChainCall; // 使用外部传入的 isChainCall 参数
              }
            }
          }
        }
      }

      try {
        // 解析 baseUrl
        final resolvedBaseUrl =
            HttpUtilSafeCall._resolveBaseUrl(baseUrl, service);

        // 构建请求选项，包含特定请求头
        dio_package.Options? options;
        if (headers != null && headers.isNotEmpty) {
          options = dio_package.Options(headers: headers);
        }

        // 直接调用 request 方法获取原始 response
        final rawResponse = await HttpUtil.instance.request<T>(
          method: method,
          path: path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          baseUrl: resolvedBaseUrl,
        );

        // 检查 500 错误
        if (rawResponse.statusCode == 500) {
          return _handleNetworkError<T>();
        }

        // 使用用户配置的解析器解析响应
        final config = _config;
        if (config == null) {
          throw StateError('HttpUtil 未配置，请先调用 HttpUtil.configure() 进行配置');
        }

        final response = config.responseParser.parse<T>(rawResponse);

        // 自动处理错误（如果用户实现了 handleError 方法）
        if (!response.isSuccess) {
          response.handleError();

          // 延迟调用全局的错误处理回调，确保链式调用的 onFailure 可以先执行
          // 优先级：链式调用的 onFailure > on401Unauthorized > 全局的 onFailure
          final errorMessage = response.errorMessage;
          if (errorMessage != null) {
            final httpStatusCode = response.httpStatusCode; // 获取 HTTP 状态码
            final errorCode = response.errorCode; // 获取业务错误码
            Future.microtask(() {
              // 再次检查 errorHandled，如果链式调用的 onFailure 已经处理了，就不调用全局的错误处理
              if (!response.errorHandled) {
                // 优先级 1：401 且设置了 on401Unauthorized
                if (httpStatusCode == 401 && config.on401Unauthorized != null) {
                  // 检查是否需要去重
                  if (HttpUtilSafeCall._shouldHandleError(401, config.errorDeduplicationWindow)) {
                    config.on401Unauthorized!();
                  }
                  // 401 已由 on401Unauthorized 处理，不再调用 onFailure
                  return;
                }

                // 优先级 2：其他错误或 401 但没有设置 on401Unauthorized
                if (config.onFailure != null) {
                  config.onFailure!(httpStatusCode, errorCode, errorMessage);
                }
              }
            });
          }
        }

        return response;
      } catch (e) {
        // 所有异常都统一处理为网络错误
        return _handleNetworkError<T>();
      } finally {
        // 如果不是链式调用（通过 http.isLoading.send() 标记），延迟关闭加载提示并清理 _chainLoadingId
        // 使用 Future.microtask 确保在扩展方法（如 extractField、onSuccess、extractModel）之后执行
        // 如果是链式调用（isChainCallFlag = true），加载提示会在整个链路结束时关闭（由 thenWithUpdate 等方法关闭）
        // 注意：extractModel、extractField 等方法不再关闭 loading，统一由 finally 块或链式调用的最后一步关闭
        if (isLoading && loadingId != null && !isChainCallFlag) {
          Future.microtask(() {
            // 再次检查 loadingId 是否仍然存在，并且确保不是链式调用
            // 如果用户只使用了 await http.send(isLoading: true)，这里会关闭 loading
            // 如果用户使用了 extractModel 等方法但没有后续链式调用，这里也会关闭 loading
            // 如果用户使用了 thenWith 等链式调用，loading 会由链式调用的最后一步关闭
            // 关键：如果 _chainLoadingId 仍然存在且等于当前 loadingId，说明没有后续链式调用，可以关闭
            // 如果 _chainLoadingId 已经被后续链式调用修改或清空，说明有链式调用，不应该关闭
            if (HttpUtil._chainLoadingId == loadingId) {
              _hideLoading(loadingId);
              HttpUtil._chainLoadingId = null;
            }
          });
        }
      }
    }

    // 如果启用了队列且未跳过队列，加入队列
    if (HttpUtil._requestQueue != null && !skipQueue) {
      return HttpUtil._requestQueue!.enqueue<Response<T>>(
        priority: priority,
        requestExecutor: () {
          // 如果启用了去重且未跳过去重，使用去重管理器
          if (HttpUtil._deduplicator != null && !skipDeduplication) {
            // 解析 baseUrl 用于去重
            final resolvedBaseUrl =
                HttpUtilSafeCall._resolveBaseUrl(baseUrl, service);
            return HttpUtil._deduplicator!.execute<Response<T>>(
              method: method,
              path: path,
              queryParameters: queryParameters,
              data: data,
              baseUrl: resolvedBaseUrl,
              requestExecutor: executeRequest,
            );
          } else {
            return executeRequest();
          }
        },
      );
    }

    // 如果启用了去重且未跳过去重，使用去重管理器
    if (HttpUtil._deduplicator != null && !skipDeduplication) {
      // 解析 baseUrl 用于去重
      final resolvedBaseUrl =
          HttpUtilSafeCall._resolveBaseUrl(baseUrl, service);
      return HttpUtil._deduplicator!.execute<Response<T>>(
        method: method,
        path: path,
        queryParameters: queryParameters,
        data: data,
        baseUrl: resolvedBaseUrl,
        requestExecutor: executeRequest,
      );
    }

    // 直接执行请求
    return executeRequest();
  }
}

/// HttpUtil 文件上传扩展方法
extension HttpUtilFileUpload on HttpUtil {
  /// 上传单个文件
  ///
  /// [path] 请求路径
  /// [file] 文件对象（File、String 路径或 Uint8List 字节数组）
  /// [fieldName] 表单字段名（默认 'file'）
  /// [fileName] 文件名（可选，如果不提供则自动提取）
  /// [contentType] Content-Type（可选，如果不提供则自动推断）
  /// [additionalData] 额外的表单数据（除了文件之外的其他字段）
  /// [queryParameters] URL 查询参数
  /// [onProgress] 上传进度回调 (已上传字节数, 总字节数)
  /// [cancelToken] 取消令牌
  /// [headers] 特定请求的请求头（可选），会与全局请求头合并，如果键相同则覆盖全局请求头
  ///
  /// 示例：
  /// ```dart
  /// final response = await http.uploadFile<String>(
  ///   path: '/api/upload',
  ///   file: File('/path/to/image.jpg'),
  ///   fieldName: 'avatar',
  ///   additionalData: {'userId': '123'},
  ///   headers: {'X-Upload-Type': 'avatar'}, // 特定请求头
  ///   onProgress: (sent, total) {
  ///     print('上传进度: ${(sent / total * 100).toStringAsFixed(1)}%');
  ///   },
  /// );
  /// ```
  Future<Response<T>> uploadFile<T>({
    required String path,
    dynamic file,
    String fieldName = 'file',
    String? fileName,
    String? contentType,
    Map<String, dynamic>? additionalData,
    Map<String, dynamic>? queryParameters,
    void Function(int sent, int total)? onProgress,
    dio_package.CancelToken? cancelToken,
    Map<String, String>? headers,
  }) async {
    // 将 file 参数转换为 UploadFile
    UploadFile uploadFile;
    if (file is File) {
      uploadFile = UploadFile(
        file: file,
        fieldName: fieldName,
        fileName: fileName,
        contentType: contentType,
      );
    } else if (file is String) {
      uploadFile = UploadFile(
        filePath: file,
        fieldName: fieldName,
        fileName: fileName,
        contentType: contentType,
      );
    } else if (file is Uint8List) {
      uploadFile = UploadFile(
        fileBytes: file,
        fieldName: fieldName,
        fileName: fileName,
        contentType: contentType,
      );
    } else {
      throw ArgumentError('file 参数必须是 File、String 或 Uint8List 类型');
    }

    return uploadFiles<T>(
      path: path,
      files: [uploadFile],
      additionalData: additionalData,
      queryParameters: queryParameters,
      onProgress: onProgress,
      cancelToken: cancelToken,
      headers: headers,
    );
  }

  /// 上传多个文件
  ///
  /// [path] 请求路径
  /// [files] 文件列表
  /// [additionalData] 额外的表单数据（除了文件之外的其他字段）
  /// [queryParameters] URL 查询参数
  /// [onProgress] 上传进度回调 (已上传字节数, 总字节数)
  /// [cancelToken] 取消令牌
  /// [headers] 特定请求的请求头（可选），会与全局请求头合并，如果键相同则覆盖全局请求头
  ///
  /// 示例：
  /// ```dart
  /// final response = await http.uploadFiles<String>(
  ///   path: '/api/upload/multiple',
  ///   files: [
  ///     UploadFile(file: File('/path/to/file1.jpg'), fieldName: 'images[]'),
  ///     UploadFile(file: File('/path/to/file2.jpg'), fieldName: 'images[]'),
  ///   ],
  ///   additionalData: {'albumId': '456'},
  ///   headers: {'X-Upload-Type': 'batch'}, // 特定请求头
  ///   onProgress: (sent, total) {
  ///     print('上传进度: ${(sent / total * 100).toStringAsFixed(1)}%');
  ///   },
  /// );
  /// ```
  Future<Response<T>> uploadFiles<T>({
    required String path,
    required List<UploadFile> files,
    Map<String, dynamic>? additionalData,
    Map<String, dynamic>? queryParameters,
    void Function(int sent, int total)? onProgress,
    dio_package.CancelToken? cancelToken,
    Map<String, String>? headers,
  }) async {
    // 验证文件列表不为空
    if (files.isEmpty) {
      throw ArgumentError('文件列表不能为空，请至少提供一个文件');
    }

    try {
      // 构建 FormData
      final formData = dio_package.FormData();

      // 添加文件
      for (final uploadFile in files) {
        final multipartFile = await uploadFile.toMultipartFile();
        formData.files.add(
          MapEntry(uploadFile.fieldName, multipartFile),
        );
      }

      // 添加额外数据
      if (additionalData != null) {
        additionalData.forEach((key, value) {
          formData.fields.add(MapEntry(key, value.toString()));
        });
      }

      // 转换进度回调格式
      dio_package.ProgressCallback? dioProgressCallback;
      if (onProgress != null) {
        dioProgressCallback = (sent, total) {
          onProgress(sent, total);
        };
      }

      // 构建请求选项，包含特定请求头
      dio_package.Options? options;
      if (headers != null && headers.isNotEmpty) {
        options = dio_package.Options(headers: headers);
      }

      // 调用 request 方法以支持进度回调
      final rawResponse = await HttpUtil.instance.request<T>(
        method: hm.post,
        path: path,
        data: formData,
        queryParameters: queryParameters,
        options: options,
        onSendProgress: dioProgressCallback,
        cancelToken: cancelToken,
      );

      // 检查 500 错误
      if (rawResponse.statusCode == 500) {
        return _handleNetworkError<T>();
      }

      // 使用用户配置的解析器解析响应
      final config = HttpUtilSafeCall._config;
      if (config == null) {
        throw StateError('HttpUtil 未配置，请先调用 HttpUtil.configure() 进行配置');
      }

      final response = config.responseParser.parse<T>(rawResponse);

      // 自动处理错误（如果用户实现了 handleError 方法）
      if (!response.isSuccess) {
        response.handleError();

        // 延迟调用全局的 onFailure，确保链式调用的 onFailure 可以先执行
        // 优先级：链式调用的 onFailure > 全局的 onFailure（如果用户使用了链式调用的 onFailure，就不调用全局的 onFailure）
        final errorMessage = response.errorMessage;
        if (errorMessage != null && config.onFailure != null) {
          final httpStatusCode = response.httpStatusCode; // 获取 HTTP 状态码
          final errorCode = response.errorCode; // 获取业务错误码
          Future.microtask(() {
            // 再次检查 errorHandled，如果链式调用的 onFailure 已经处理了，就不调用全局的 onFailure
            if (!response.errorHandled) {
              config.onFailure!(httpStatusCode, errorCode, errorMessage);
            }
          });
        }
      }

      return response;
    } catch (e) {
      // 所有异常都统一处理为网络错误
      return _handleNetworkError<T>();
    }
  }

  /// 处理网络错误（内部方法，从 HttpUtilSafeCall 复制）
  Response<T> _handleNetworkError<T>() {
    final config = HttpUtilSafeCall._config;
    final errorMessage = config?.networkErrorKey ?? '网络错误，请稍后重试！';

    if (config?.onFailure != null) {
      config!.onFailure!(null, null, errorMessage); // 网络错误没有 httpStatusCode 和 errorCode
    }

    return SimpleErrorResponse<T>(errorMessage);
  }

  /// 直接上传文件到外部 URL（OSS 直传）
  ///
  /// 适用于后端返回预签名上传 URL 的场景，直接上传到 OSS（阿里云、腾讯云等）
  /// 返回 Response<T>，支持链式调用和自动错误处理
  ///
  /// [uploadUrl] 完整的上传 URL（包含签名参数）
  /// [file] 文件对象（File、String 路径或 Uint8List 字节数组）
  /// [method] HTTP 方法，默认为 'PUT'（OSS 通常使用 PUT）
  /// [headers] 自定义请求头（OSS 通常需要签名头，如 'Authorization', 'Content-Type' 等）
  /// [onProgress] 上传进度回调 (已上传字节数, 总字节数)
  /// [cancelToken] 取消令牌
  ///
  /// 示例（链式调用）：
  /// ```dart
  /// final result = await http
  ///   .send(...)
  ///   .extractModel<FileUploadResult>(FileUploadResult.fromConfigJson)
  ///   .thenWith((uploadResult) => http.uploadToUrlResponse(
  ///     uploadUrl: uploadResult.uploadUrl,
  ///     file: file,
  ///     method: 'PUT',
  ///     headers: uploadResult.contentType != null
  ///         ? {'Content-Type': uploadResult.contentType!}
  ///         : null,
  ///   ));
  /// ```
  ///
  /// 示例（单独使用）：
  /// ```dart
  /// final response = await http.uploadToUrlResponse(
  ///   uploadUrl: uploadUrl,
  ///   file: File('/path/to/image.jpg'),
  ///   method: 'PUT',
  ///   headers: {'Content-Type': 'image/jpeg'},
  ///   onProgress: (sent, total) {
  ///     print('上传进度: ${(sent / total * 100).toStringAsFixed(1)}%');
  ///   },
  /// );
  ///
  /// if (response.isSuccess) {
  ///   print('上传成功');
  /// }
  /// ```
  Future<Response<T>> uploadToUrlResponse<T>({
    required String uploadUrl,
    required dynamic file,
    String method = 'PUT',
    Map<String, String>? headers,
    void Function(int sent, int total)? onProgress,
    dio_package.CancelToken? cancelToken,
  }) async {
    try {
      final dioResponse = await _uploadToUrlInternal(
        uploadUrl: uploadUrl,
        file: file,
        method: method,
        headers: headers,
        onProgress: onProgress,
        cancelToken: cancelToken,
      );

      // 将 dio_package.Response 转换为 Response<T>
      // OSS 直传成功通常返回 200 或 204
      final isSuccess = dioResponse.statusCode != null &&
          (dioResponse.statusCode == 200 || dioResponse.statusCode == 204);

      final response = ApiResponse<T>(
        code: dioResponse.statusCode ?? -1,
        message: isSuccess ? '上传成功' : '上传失败',
        data: dioResponse.data as T?,
        isSuccess: isSuccess,
      );

      // 如果上传失败，自动处理错误（触发错误提示）
      if (!isSuccess) {
        final config = HttpUtilSafeCall._config;
        final errorMessage = response.errorMessage ?? '上传失败，请稍后重试！';
        // 调用 handleError（保持接口兼容性，实际错误处理由 HttpConfig.onFailure 统一处理）
        response.handleError();
        // 延迟调用全局的 onFailure，确保链式调用的 onFailure 可以先执行
        // 优先级：链式调用的 onFailure > 全局的 onFailure（如果用户使用了链式调用的 onFailure，就不调用全局的 onFailure）
        if (config?.onFailure != null) {
          final httpStatusCode = response.httpStatusCode; // 获取 HTTP 状态码
          final errorCode = response.errorCode; // 获取业务错误码
          Future.microtask(() {
            // 再次检查 errorHandled，如果链式调用的 onFailure 已经处理了，就不调用全局的 onFailure
            if (!response.errorHandled) {
              config!.onFailure!(httpStatusCode, errorCode, errorMessage);
            }
          });
        }
      }

      return response;
    } catch (e) {
      // 处理错误
      final config = HttpUtilSafeCall._config;
      final errorMessage = config?.networkErrorKey ?? '上传失败，请稍后重试！';

      if (config?.onFailure != null) {
        config!.onFailure!(null, null, errorMessage); // 上传异常没有 httpStatusCode 和 errorCode
      }

      return ApiResponse<T>(
        code: -1,
        message: errorMessage,
        data: null,
        isSuccess: false,
      );
    }
  }

  /// 内部上传方法（提取公共逻辑）
  Future<dio_package.Response> _uploadToUrlInternal({
    required String uploadUrl,
    required dynamic file,
    String method = 'PUT',
    Map<String, String>? headers,
    void Function(int sent, int total)? onProgress,
    dio_package.CancelToken? cancelToken,
  }) async {
    // 验证 URL 格式
    try {
      Uri.parse(uploadUrl);
    } catch (e) {
      throw ArgumentError('无效的上传 URL: $uploadUrl');
    }

    // 验证 HTTP 方法
    final upperMethod = method.toUpperCase();
    if (!['GET', 'POST', 'PUT', 'PATCH', 'DELETE'].contains(upperMethod)) {
      throw ArgumentError('不支持的 HTTP 方法: $method');
    }

    // 创建独立的 Dio 实例（不依赖 baseUrl 配置）
    final dio = HttpUtil.createDio();

    try {
      // 准备文件数据
      Uint8List fileBytes;

      if (file is File) {
        if (!await file.exists()) {
          throw FileSystemException('文件不存在', file.path);
        }
        fileBytes = await file.readAsBytes();
      } else if (file is String) {
        final fileObj = File(file);
        if (!await fileObj.exists()) {
          throw FileSystemException('文件不存在', file);
        }
        fileBytes = await fileObj.readAsBytes();
      } else if (file is Uint8List) {
        fileBytes = file;
      } else {
        throw ArgumentError('file 参数必须是 File、String 或 Uint8List 类型');
      }

      // 转换进度回调格式
      dio_package.ProgressCallback? dioProgressCallback;
      if (onProgress != null) {
        dioProgressCallback = (sent, total) {
          // 处理 Dio 可能返回 -1 的情况（未知大小）
          if (sent >= 0 && total >= 0) {
            onProgress(sent, total);
          }
        };
      }

      // 设置请求头
      final options = dio_package.Options(
        method: upperMethod,
        headers: headers,
        // OSS 直传通常不需要响应解析，直接返回原始响应
        validateStatus: (status) => true,
      );

      // 执行上传
      final response = await dio.request(
        uploadUrl,
        data: fileBytes,
        options: options,
        onSendProgress: dioProgressCallback,
        cancelToken: cancelToken,
      );

      return response;
    } catch (e) {
      if (e is dio_package.DioException) {
        rethrow;
      }
      if (e is FileSystemException || e is ArgumentError) {
        rethrow;
      }
      throw Exception('上传失败: $e');
    } finally {
      // Dio 实例会自动管理连接池，通常不需要手动关闭
      // 但为了确保资源释放，我们可以关闭它（可选）
      // dio.close(); // Dio 5.x 没有 close 方法，连接池会自动管理
    }
  }
}

/// HttpUtil 文件下载扩展方法
extension HttpUtilFileDownload on HttpUtil {
  /// 下载文件
  ///
  /// [path] 请求路径（相对于 baseUrl）或完整 URL（如 'https://cdn.example.com/file.pdf'）
  ///        - 如果是相对路径（如 '/api/download/file.pdf'），会使用配置的 baseUrl
  ///        - 如果是完整 URL（如 'https://cdn.example.com/file.pdf'），会直接使用该 URL，忽略 baseUrl
  /// [savePath] 保存文件的完整路径（包括文件名）
  /// [queryParameters] URL 查询参数（仅在 path 为相对路径时有效，完整 URL 的查询参数应包含在 URL 中）
  /// [headers] 特定请求的请求头（可选），会与全局请求头合并，如果键相同则覆盖全局请求头
  /// [onProgress] 下载进度回调 (已下载字节数, 总字节数)
  /// [cancelToken] 取消令牌
  /// [deleteOnError] 下载失败时是否删除已下载的文件（默认 true）
  /// [resumeOnError] 是否支持断点续传（默认 true），如果为 true，下载失败后可以继续下载
  ///
  /// **返回值：**
  /// - 返回 `Future<DownloadResponse<String>>`，其中 `data` 字段为文件路径
  /// - 可以通过 `response.isSuccess` 检查是否成功
  /// - 可以通过 `response.filePath` 获取下载的文件路径
  ///
  /// **断点续传：**
  /// - 如果 `resumeOnError` 为 true，下载失败后再次调用相同路径和保存路径时，会自动从断点继续下载
  /// - 断点续传通过 HTTP Range 请求头实现
  /// - 如果文件已存在且完整，会直接返回成功，不会重新下载
  ///
  /// **示例（相对路径）：**
  /// ```dart
  /// final response = await http.downloadFile(
  ///   path: '/api/download/file.pdf',
  ///   savePath: '/path/to/save/file.pdf',
  ///   onProgress: (received, total) {
  ///     print('下载进度: ${(received / total * 100).toStringAsFixed(1)}%');
  ///   },
  /// );
  /// ```
  ///
  /// **示例（完整 URL）：**
  /// ```dart
  /// // 从 CDN 或其他服务器下载，不依赖 baseUrl
  /// final response = await http.downloadFile(
  ///   path: 'https://cdn.example.com/files/file.pdf',
  ///   savePath: '/path/to/save/file.pdf',
  ///   onProgress: (received, total) {
  ///     print('下载进度: ${(received / total * 100).toStringAsFixed(1)}%');
  ///   },
  /// );
  /// ```
  ///
  /// **示例（断点续传）：**
  /// ```dart
  /// // 第一次下载（可能失败）
  /// final response1 = await http.downloadFile(
  ///   path: '/api/download/large-file.zip',
  ///   savePath: '/path/to/save/large-file.zip',
  ///   resumeOnError: true, // 启用断点续传
  /// );
  ///
  /// // 如果下载失败，再次调用会自动从断点继续
  /// if (!response1.isSuccess) {
  ///   final response2 = await http.downloadFile(
  ///     path: '/api/download/large-file.zip',
  ///     savePath: '/path/to/save/large-file.zip',
  ///     resumeOnError: true,
  ///   );
  /// }
  /// ```
  ///
  /// **示例（特定请求头）：**
  /// ```dart
  /// final response = await http.downloadFile(
  ///   path: '/api/download/private-file.pdf',
  ///   savePath: '/path/to/save/file.pdf',
  ///   headers: {'X-Download-Type': 'private'}, // 特定请求头
  /// );
  /// ```
  ///
  /// **示例（多服务支持）：**
  /// ```dart
  /// // 使用默认 baseUrl
  /// await http.downloadFile(
  ///   path: '/api/download/file.pdf',
  ///   savePath: '/path/to/save/file.pdf',
  /// );
  ///
  /// // 使用服务
  /// await http.downloadFile(
  ///   path: '/download/file.pdf',
  ///   savePath: '/path/to/save/file.pdf',
  ///   service: 'files', // 使用 files 服务
  /// );
  ///
  /// // 直接指定 baseUrl
  /// await http.downloadFile(
  ///   path: '/download/file.pdf',
  ///   savePath: '/path/to/save/file.pdf',
  ///   baseUrl: 'https://cdn.example.com',
  /// );
  /// ```
  Future<DownloadResponse<String>> downloadFile({
    required String path,
    required String savePath,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    void Function(int received, int total)? onProgress,
    dio_package.CancelToken? cancelToken,
    bool deleteOnError = true,
    bool resumeOnError = true,
    String? baseUrl, // 直接指定 baseUrl（最高优先级）
    String? service, // 使用 serviceBaseUrls 中定义的服务名称
  }) async {
    try {
      // 检查 path 是否是完整 URL
      final isAbsoluteUrl = _isAbsoluteUrl(path);

      // 如果是完整 URL，使用独立的 Dio 实例（不依赖 baseUrl 和拦截器）
      // 如果是相对路径，解析 baseUrl 并使用对应的 Dio 实例
      final dio = isAbsoluteUrl
          ? HttpUtil.createDio()
          : HttpUtil.instance._getDioForBaseUrl(
              HttpUtilSafeCall._resolveBaseUrl(baseUrl, service),
            );

      // 获取配置（用于请求头和错误处理）
      final config = HttpUtilSafeCall._config;
      if (config == null && !isAbsoluteUrl) {
        throw StateError('HttpUtil 未配置，请先调用 HttpUtil.configure() 进行配置');
      }

      // 检查保存路径的目录是否存在，如果不存在则创建
      final file = File(savePath);
      final directory = file.parent;
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // 检查文件是否已存在（用于断点续传）
      int? startByte;
      if (resumeOnError && await file.exists()) {
        final fileLength = await file.length();
        if (fileLength > 0) {
          startByte = fileLength;
        }
      }

      // 构建请求选项
      final requestHeaders = <String, dynamic>{};

      // 如果是完整 URL，只使用特定请求头（不合并全局请求头）
      // 如果是相对路径，先添加全局请求头，再添加特定请求头
      if (!isAbsoluteUrl && config != null) {
        // 先添加静态请求头（优先级最低）
        if (config.staticHeaders != null) {
          requestHeaders.addAll(config.staticHeaders!);
        }

        // 再添加动态请求头（优先级中等）
        if (config.dynamicHeaderBuilder != null) {
          final dynamicHeaders = await config.dynamicHeaderBuilder!();
          requestHeaders.addAll(dynamicHeaders);
        }
      }

      // 如果支持断点续传且文件已存在，添加 Range 请求头
      if (startByte != null && startByte > 0) {
        requestHeaders['Range'] = 'bytes=$startByte-';
      }

      // 最后添加特定请求头（优先级最高，会覆盖全局请求头）
      if (headers != null) {
        requestHeaders.addAll(headers);
      }

      final options = dio_package.Options(
        headers: requestHeaders,
        // 下载时不需要解析响应体
        responseType: dio_package.ResponseType.stream,
        validateStatus: (status) => true,
      );

      // 转换进度回调格式
      dio_package.ProgressCallback? dioProgressCallback;
      if (onProgress != null) {
        dioProgressCallback = (received, total) {
          // 处理断点续传的情况
          if (startByte != null && startByte > 0) {
            // 调整已接收字节数（加上已下载的部分）
            final adjustedReceived = received + startByte;
            final adjustedTotal = total >= 0 ? total + startByte : total;
            onProgress(adjustedReceived, adjustedTotal);
          } else {
            // 处理 Dio 可能返回 -1 的情况（未知大小）
            if (received >= 0) {
              // 即使 total 为 -1（未知大小），也应该调用回调，传递已接收的字节数
              onProgress(received, total);
            }
          }
        };
      }

      // 执行下载
      // 注意：如果 path 是完整 URL，queryParameters 会被忽略（应包含在 URL 中）
      final response = await dio.get(
        path,
        queryParameters: isAbsoluteUrl ? null : queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: dioProgressCallback,
      );

      // 检查响应状态
      if (response.statusCode == null) {
        if (deleteOnError && await file.exists()) {
          await file.delete();
        }
        return DownloadResponse.failure<String>(
          errorMessage: '下载失败：无效的响应状态码',
        );
      }

      // 处理 206 Partial Content（断点续传响应）
      if (response.statusCode == 206) {
        // 断点续传成功，继续写入文件
        if (response.data is Stream) {
          final stream = response.data as Stream<List<int>>;
          // 206 响应时，如果发送了 Range 请求（startByte > 0），使用 append 模式
          // 如果 startByte 为 null（理论上不应该发生），使用 write 模式
          final fileMode = (startByte != null && startByte > 0)
              ? FileMode.append
              : FileMode.write;
          final sink = file.openWrite(mode: fileMode);

          try {
            await for (final chunk in stream) {
              sink.add(chunk);
            }
            await sink.flush();
          } catch (e) {
            // 写入文件时出错，关闭流并删除不完整的文件
            if (deleteOnError && await file.exists()) {
              await file.delete();
            }
            return DownloadResponse.failure<String>(
              errorMessage: '下载失败：写入文件时出错 - $e',
            );
          } finally {
            await sink.close();
          }
        } else {
          if (deleteOnError && await file.exists()) {
            await file.delete();
          }
          return DownloadResponse.failure<String>(
            errorMessage: '下载失败：无效的响应数据格式',
          );
        }
      } else if (response.statusCode! >= 200 && response.statusCode! < 300) {
        // 正常下载（200 OK）
        // 如果发送了 Range 请求但收到 200，说明服务器不支持断点续传
        // 需要删除已存在的文件，然后重新下载
        if (startByte != null && startByte > 0) {
          // 服务器不支持断点续传，删除已存在的文件
          if (await file.exists()) {
            await file.delete();
          }
        }

        if (response.data is Stream) {
          final stream = response.data as Stream<List<int>>;
          final sink = file.openWrite();

          try {
            await for (final chunk in stream) {
              sink.add(chunk);
            }
            await sink.flush();
          } catch (e) {
            // 写入文件时出错，关闭流并删除不完整的文件
            if (deleteOnError && await file.exists()) {
              await file.delete();
            }
            return DownloadResponse.failure<String>(
              errorMessage: '下载失败：写入文件时出错 - $e',
            );
          } finally {
            await sink.close();
          }
        } else {
          if (deleteOnError && await file.exists()) {
            await file.delete();
          }
          return DownloadResponse.failure<String>(
            errorMessage: '下载失败：无效的响应数据格式',
          );
        }
      } else {
        // 下载失败
        if (deleteOnError && await file.exists()) {
          await file.delete();
        }
        return DownloadResponse.failure<String>(
          errorMessage: '下载失败：HTTP ${response.statusCode}',
        );
      }

      // 获取文件总大小
      final totalBytes = await file.length();

      // 下载成功
      return DownloadResponse.success(
        filePath: savePath,
        totalBytes: totalBytes,
      );
    } on dio_package.DioException catch (e) {
      // Dio 异常处理
      final file = File(savePath);
      if (deleteOnError && await file.exists()) {
        await file.delete();
      }

      String errorMessage;
      if (e.type == dio_package.DioExceptionType.connectionTimeout ||
          e.type == dio_package.DioExceptionType.receiveTimeout ||
          e.type == dio_package.DioExceptionType.sendTimeout) {
        errorMessage = '下载超时，请检查网络连接';
      } else if (e.type == dio_package.DioExceptionType.cancel) {
        errorMessage = '下载已取消';
      } else if (e.type == dio_package.DioExceptionType.connectionError) {
        errorMessage = '网络连接错误，请检查网络设置';
      } else {
        errorMessage = '下载失败：${e.message ?? '未知错误'}';
      }

      // 触发错误提示
      final config = HttpUtilSafeCall._config;
      if (config?.onFailure != null) {
        config!.onFailure!(null, null, errorMessage); // 下载异常没有 httpStatusCode 和 errorCode
      }

      return DownloadResponse.failure<String>(errorMessage: errorMessage);
    } catch (e) {
      // 其他异常处理
      final file = File(savePath);
      if (deleteOnError && await file.exists()) {
        await file.delete();
      }

      final errorMessage = '下载失败：$e';

      // 触发错误提示
      final config = HttpUtilSafeCall._config;
      if (config?.onFailure != null) {
        config!.onFailure!(null, null, errorMessage); // 下载异常没有 httpStatusCode 和 errorCode
      }

      return DownloadResponse.failure<String>(errorMessage: errorMessage);
    }
  }

  /// 检查路径是否是完整 URL
  /// 如果 path 以 'http://' 或 'https://' 开头，则认为是完整 URL
  static bool _isAbsoluteUrl(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }
}

/// HttpUtil SSE 扩展方法
extension HttpUtilSSE on HttpUtil {
  /// 创建 SSE 连接管理器
  ///
  /// 用于管理多个 SSE 连接，支持同时维护多个连接
  /// 这是唯一的 SSE API，支持单连接和多连接场景
  ///
  /// **单连接场景**：
  /// ```dart
  /// final manager = http.sseManager();
  ///
  /// await manager.connect(
  ///   id: 'chat',
  ///   path: '/ai/chat/stream',
  ///   method: 'POST',
  ///   data: {'question': '你好'},
  ///   onData: (event) => print('收到: ${event.data}'),
  /// );
  ///
  /// // 断开连接
  /// await manager.disconnect('chat');
  /// ```
  ///
  /// **多连接场景**：
  /// ```dart
  /// final manager = http.sseManager();
  ///
  /// // 建立第一个连接
  /// await manager.connect(
  ///   id: 'chat',
  ///   path: '/ai/chat/stream',
  ///   method: 'POST',
  ///   data: {'question': '你好'},
  ///   onData: (event) => print('聊天: ${event.data}'),
  /// );
  ///
  /// // 建立第二个连接
  /// await manager.connect(
  ///   id: 'notifications',
  ///   path: '/notifications/stream',
  ///   onData: (event) => print('通知: ${event.data}'),
  /// );
  ///
  /// // 断开指定连接
  /// await manager.disconnect('chat');
  ///
  /// // 断开所有连接
  /// await manager.disconnectAll();
  /// ```
  SSEManager sseManager() {
    return _SSEManagerImpl();
  }
}

/// SSE 管理器实现类（内部使用）
class _SSEManagerImpl extends SSEManager {
  _SSEManagerImpl();

  @override
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
    if (hasConnection(id)) {
      if (replaceIfExists) {
        // 断开旧连接
        await disconnect(id);
      } else {
        // 不替换，直接返回
        return id;
      }
    }

    // 确保连接的 Completer 存在（在连接建立前创建）
    // 这样即使连接在 waitForAllConnectionsDone() 调用前完成，也能正确跟踪
    ensureConnectionCompleter(id);

    // 获取配置
    final config = HttpUtilSafeCall._config;
    if (config == null) {
      throw StateError('HttpUtil 未配置，请先调用 HttpUtil.configure() 进行配置');
    }

    // 解析 baseUrl
    final resolvedBaseUrl = HttpUtilSafeCall._resolveBaseUrl(baseUrl, service);

    // 直接使用 SSEConnection.connect 建立连接
    final connection = await SSEConnection.connect(
      baseUrl: resolvedBaseUrl,
      path: path,
      method: method,
      data: data,
      queryParameters: queryParameters,
      staticHeaders: config.staticHeaders,
      dynamicHeaderBuilder: config.dynamicHeaderBuilder,
      headers: headers,
    );

    // 监听事件（包装 onDone 回调，在完成后标记连接完成）
    connection.listen(
      onData: onData,
      onError: onError,
      onDone: () {
        // 先调用用户提供的 onDone 回调
        onDone?.call();
        // 然后标记连接完成
        markConnectionDone(id);
      },
    );

    // 保存连接对象
    addConnection(id, connection);

    // 创建取消函数
    addCancelFunction(id, () async {
      await connection.disconnect();
      // 断开连接时也标记完成
      markConnectionDone(id);
    });

    return id;
  }
}

/// 带加载提示的 HttpUtil 包装类
/// 用于链式调用，自动管理整个链路的加载提示
class HttpUtilWithLoading {
  final HttpUtil _httpUtil;

  HttpUtilWithLoading(this._httpUtil);

  /// 发送请求（自动显示加载提示，用于链式调用）
  /// 整个链路共享一个加载提示，在链路结束时自动关闭
  Future<Response<T>> send<T>({
    required String method,
    required String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    int priority = 0,
    bool skipDeduplication = false,
    bool skipQueue = false,
    String? baseUrl,
    String? service,
  }) {
    // 调用原始的 send 方法，但标记为链式调用
    return _httpUtil.send<T>(
      method: method,
      path: path,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      isLoading: true,
      priority: priority,
      skipDeduplication: skipDeduplication,
      skipQueue: skipQueue,
      baseUrl: baseUrl,
      service: service,
      isChainCall: true, // 标记为链式调用
    );
  }
}

/// HttpUtil 扩展方法：提供 isLoading getter
extension HttpUtilLoadingExtension on HttpUtil {
  /// 获取带加载提示的 HttpUtil 实例
  /// 用于链式调用，整个链路共享一个加载提示
  ///
  /// 示例：
  /// ```dart
  /// final result = await http.isLoading
  ///   .send(method: hm.post, path: '/api/upload')
  ///   .extractModel<FileUploadResult>(FileUploadResult.fromConfigJson)
  ///   .thenWith((uploadResult) => http.uploadToUrlResponse(...));
  /// ```
  HttpUtilWithLoading get isLoading => HttpUtilWithLoading(this);
}

/// 全局 HTTP 请求实例（简化调用）
/// 使用方式：http.send(method: hm.post, path: '/api/user', ...)
/// 注意：使用前必须先调用 HttpUtil.configure() 进行配置
final http = HttpUtil.instance;
