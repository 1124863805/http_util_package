import 'package:dio/dio.dart' as dio_package;
import 'http_config.dart';
import 'api_response.dart';
import 'http_method.dart';

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
    // 配置 ApiResponse 的错误处理器
    ApiResponse.setErrorHandler(config.onError);
  }

  /// 获取 Dio 实例
  static dio_package.Dio get dio {
    if (_dioInstance == null) {
      if (_config == null) {
        throw StateError(
            'HttpUtil 未配置，请先调用 HttpUtil.configure() 进行配置');
      }

      _dioInstance = dio_package.Dio();
      _dioInstance!.options = dio_package.BaseOptions(
        baseUrl: _config!.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        // 所有状态码都认为是有效的，不自动抛出异常
        validateStatus: (status) => true,
      );

      // 添加请求拦截器，自动添加请求头
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
    }
    return _dioInstance!;
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
        throw ArgumentError(
            '不支持的请求方式: $method，请使用 hm 常量（hm.get、hm.post 等）');
    }
  }
}

/// HttpUtil 扩展方法
/// 提供安全调用方法，自动处理异常和错误提示
extension HttpUtilSafeCall on HttpUtil {
  /// 获取配置（内部使用）
  static HttpConfig? get _config => HttpUtil._config;

  /// 处理网络错误（统一提示）
  ApiResponse<T> _handleNetworkError<T>() {
    final config = _config;
    if (config == null) {
      return ApiResponse<T>(
          code: -1, message: '网络错误，请稍后重试！', data: null);
    }

    final errorMessage = config.networkErrorKey ?? '网络错误，请稍后重试！';
    final title = config.tipTitleKey ?? '提示';

    if (config.onError != null) {
      config.onError!(title, errorMessage);
    }

    return ApiResponse<T>(code: -1, message: errorMessage, data: null);
  }

  /// 发送请求（自动处理异常，失败时自动提示）
  /// [method] 请求方式：必须使用 hm.get、hm.post 等常量
  Future<ApiResponse<T>> send<T>({
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

      final response = ApiResponse<T>.fromResponse(rawResponse);
      if (!response.isSuccess) {
        response.handleError();
      }
      return response;
    } catch (e) {
      if (e is dio_package.DioException) {
        return _handleNetworkError<T>();
      }
      return _handleNetworkError<T>();
    }
  }
}

/// 全局 HTTP 请求实例（简化调用）
/// 使用方式：http.send(method: hm.post, path: '/api/user', ...)
/// 注意：使用前必须先调用 HttpUtil.configure() 进行配置
final http = HttpUtil.instance;
