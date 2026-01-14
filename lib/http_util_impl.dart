import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart' as dio_package;
import 'http_config.dart';
import 'response.dart';
import 'http_method.dart';
import 'log_interceptor.dart';
import 'simple_error_response.dart';
import 'upload_file.dart';
import 'sse/sse_client.dart';
import 'sse/sse_event.dart';

/// HTTP 请求工具类
/// 基于 Dio 封装，支持配置化的请求头注入
class HttpUtil {
  HttpUtil._();

  static HttpUtil? _instance;
  static dio_package.Dio? _dioInstance;
  static HttpConfig? _config;

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
              // 添加静态请求头
              if (_config!.staticHeaders != null) {
                options.headers.addAll(_config!.staticHeaders!);
              }

              // 添加动态请求头
              if (_config!.dynamicHeaderBuilder != null) {
                final dynamicHeaders = await _config!.dynamicHeaderBuilder!();
                options.headers.addAll(dynamicHeaders);
              }

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
  Future<dio_package.Response> request<T>({
    required String method,
    required String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    dio_package.Options? options,
    dio_package.CancelToken? cancelToken,
    dio_package.ProgressCallback? onSendProgress,
    dio_package.ProgressCallback? onReceiveProgress,
  }) async {
    final upperMethod = method.toUpperCase();

    switch (upperMethod) {
      case hm.get:
        return dio.get<T>(
          path,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
          onReceiveProgress: onReceiveProgress,
        );
      case hm.post:
        return dio.post<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
          onSendProgress: onSendProgress,
          onReceiveProgress: onReceiveProgress,
        );
      case hm.put:
        return dio.put<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
          onSendProgress: onSendProgress,
          onReceiveProgress: onReceiveProgress,
        );
      case hm.delete:
        return dio.delete<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
        );
      case hm.patch:
        return dio.patch<T>(
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
}

/// HttpUtil 扩展方法
/// 提供安全调用方法，自动处理异常和错误提示
extension HttpUtilSafeCall on HttpUtil {
  /// 获取配置（内部使用）
  static HttpConfig? get _config => HttpUtil._config;

  /// 处理网络错误（统一提示）
  /// 返回一个表示网络错误的 Response
  /// 注意：这里返回的 Response 需要由用户通过 ResponseParser 定义
  /// 但为了错误处理，我们创建一个简单的错误 Response
  Response<T> _handleNetworkError<T>() {
    final config = _config;
    final errorMessage = config?.networkErrorKey ?? '网络错误，请稍后重试！';

    if (config?.onError != null) {
      config!.onError!(errorMessage);
    }

    // 返回一个简单的错误 Response
    // 用户应该在自己的 ResponseParser 中处理网络错误，这里只是兜底
    return SimpleErrorResponse<T>(errorMessage);
  }

  /// 发送请求（自动处理异常，失败时自动提示）
  /// [method] 请求方式：必须使用 hm.get、hm.post 等常量
  Future<Response<T>> send<T>({
    required String method,
    required String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      // 直接调用 request 方法获取原始 response
      final rawResponse = await HttpUtil.instance.request<T>(
        method: method,
        path: path,
        data: data,
        queryParameters: queryParameters,
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

        // 如果用户没有实现 handleError，使用配置的 onError 回调
        final errorMessage = response.errorMessage;
        if (errorMessage != null && config.onError != null) {
          config.onError!(errorMessage);
        }
      }

      return response;
    } catch (e) {
      // 所有异常都统一处理为网络错误
      return _handleNetworkError<T>();
    }
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
  ///
  /// 示例：
  /// ```dart
  /// final response = await http.uploadFile<String>(
  ///   path: '/api/upload',
  ///   file: File('/path/to/image.jpg'),
  ///   fieldName: 'avatar',
  ///   additionalData: {'userId': '123'},
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

      // 调用 request 方法以支持进度回调
      final rawResponse = await HttpUtil.instance.request<T>(
        method: hm.post,
        path: path,
        data: formData,
        queryParameters: queryParameters,
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

        // 如果用户没有实现 handleError，使用配置的 onError 回调
        final errorMessage = response.errorMessage;
        if (errorMessage != null && config.onError != null) {
          config.onError!(errorMessage);
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

    if (config?.onError != null) {
      config!.onError!(errorMessage);
    }

    return SimpleErrorResponse<T>(errorMessage);
  }

  /// 直接上传文件到外部 URL（OSS 直传）
  ///
  /// 适用于后端返回预签名上传 URL 的场景，直接上传到 OSS（阿里云、腾讯云等）
  ///
  /// [uploadUrl] 完整的上传 URL（包含签名参数）
  /// [file] 文件对象（File、String 路径或 Uint8List 字节数组）
  /// [method] HTTP 方法，默认为 'PUT'（OSS 通常使用 PUT）
  /// [headers] 自定义请求头（OSS 通常需要签名头，如 'Authorization', 'Content-Type' 等）
  /// [onProgress] 上传进度回调 (已上传字节数, 总字节数)
  /// [cancelToken] 取消令牌
  ///
  /// 示例（阿里云 OSS）：
  /// ```dart
  /// // 1. 从后端获取预签名上传 URL
  /// final uploadInfo = await http.send<Map<String, dynamic>>(
  ///   method: hm.post,
  ///   path: '/api/oss/upload-url',
  ///   data: {'fileName': 'image.jpg', 'contentType': 'image/jpeg'},
  /// );
  ///
  /// final uploadUrl = uploadInfo.extract<String>(
  ///   (data) => (data as Map)['uploadUrl'] as String?,
  /// );
  ///
  /// if (uploadUrl != null) {
  ///   // 2. 直接上传到 OSS
  ///   final response = await http.uploadToUrl(
  ///     uploadUrl: uploadUrl,
  ///     file: File('/path/to/image.jpg'),
  ///     method: 'PUT',
  ///     headers: {
  ///       'Content-Type': 'image/jpeg',
  ///       // OSS 签名头通常已经在 URL 中，不需要额外添加
  ///     },
  ///     onProgress: (sent, total) {
  ///       print('上传进度: ${(sent / total * 100).toStringAsFixed(1)}%');
  ///     },
  ///   );
  ///
  ///   if (response.statusCode == 200 || response.statusCode == 204) {
  ///     print('上传成功');
  ///   }
  /// }
  /// ```
  ///
  /// 示例（腾讯云 COS，使用 POST 表单上传）：
  /// ```dart
  /// final response = await http.uploadToUrl(
  ///   uploadUrl: uploadUrl,
  ///   file: File('/path/to/image.jpg'),
  ///   method: 'POST',
  ///   headers: {
  ///     'Content-Type': 'multipart/form-data',
  ///   },
  /// );
  /// ```
  Future<dio_package.Response> uploadToUrl({
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

/// HttpUtil SSE 扩展方法
extension HttpUtilSSE on HttpUtil {
  /// 建立 Server-Sent Events (SSE) 连接（自动连接）
  ///
  /// [path] 请求路径
  /// [queryParameters] URL 查询参数
  ///
  /// 返回已连接的事件流，可以直接监听
  /// 注意：流关闭时会自动清理资源，无需手动调用 close()
  ///
  /// 示例：
  /// ```dart
  /// // 自动连接并监听事件
  /// final stream = await http.sse(
  ///   path: '/api/events',
  ///   queryParameters: {'topic': 'notifications'},
  /// );
  ///
  /// final subscription = stream.listen(
  ///   (event) {
  ///     print('收到事件: ${event.data}');
  ///   },
  ///   onError: (error) {
  ///     print('SSE 错误: $error');
  ///   },
  ///   onDone: () {
  ///     print('SSE 连接关闭');
  ///   },
  /// );
  ///
  /// // 取消订阅时会自动清理资源
  /// // subscription.cancel();
  /// ```
  ///
  /// 如果需要手动控制连接，使用 `sseClient()` 方法
  Future<Stream<SSEEvent>> sse({
    required String path,
    Map<String, String>? queryParameters,
  }) async {
    final client = sseClient(
      path: path,
      queryParameters: queryParameters,
    );

    // 如果连接失败，确保清理资源
    try {
      await client.connect();
    } catch (e) {
      // 连接失败时清理客户端资源
      await client.close();
      rethrow;
    }

    // 创建包装流，在流关闭时自动清理客户端资源
    final controller = StreamController<SSEEvent>.broadcast();
    late StreamSubscription<SSEEvent> subscription;
    // 使用标志位防止 client.close() 被重复调用（竞态条件保护）
    bool _clientClosed = false;

    subscription = client.events.listen(
      (event) {
        if (!controller.isClosed) {
          controller.add(event);
        }
      },
      onError: (error) {
        if (!controller.isClosed) {
          controller.addError(error);
        }
      },
      onDone: () {
        if (!controller.isClosed) {
          controller.close();
        }
        // 流关闭时自动清理资源（使用标志位防止重复关闭）
        if (!_clientClosed) {
          _clientClosed = true;
          client.close();
        }
      },
      cancelOnError: false,
    );

    // 如果控制器被关闭（用户取消订阅），也要清理资源
    controller.onCancel = () {
      subscription.cancel();
      // 使用标志位防止重复关闭（竞态条件保护）
      if (!_clientClosed) {
        _clientClosed = true;
        client.close();
      }
    };

    return controller.stream;
  }

  /// 创建 SSE 客户端（不自动连接）
  ///
  /// 适用于需要手动控制连接时机的场景
  ///
  /// 示例：
  /// ```dart
  /// final client = http.sseClient(
  ///   path: '/api/events',
  /// );
  ///
  /// // 稍后手动连接
  /// await client.connect();
  ///
  /// client.events.listen((event) {
  ///   print('收到事件: ${event.data}');
  /// });
  ///
  /// // 关闭连接
  /// await client.close();
  /// ```
  SSEClient sseClient({
    required String path,
    Map<String, String>? queryParameters,
  }) {
    final config = HttpUtilSafeCall._config;
    if (config == null) {
      throw StateError('HttpUtil 未配置，请先调用 HttpUtil.configure() 进行配置');
    }

    return SSEClient(
      baseUrl: config.baseUrl,
      path: path,
      queryParameters: queryParameters,
      staticHeaders: config.staticHeaders,
      dynamicHeaderBuilder: config.dynamicHeaderBuilder,
    );
  }
}

/// 全局 HTTP 请求实例（简化调用）
/// 使用方式：http.send(method: hm.post, path: '/api/user', ...)
/// 注意：使用前必须先调用 HttpUtil.configure() 进行配置
final http = HttpUtil.instance;
