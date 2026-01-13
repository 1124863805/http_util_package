import 'package:dio/dio.dart' as dio_package;
import 'package:get/get.dart';
import '../config/app_config.dart';
import '../services/locale_service.dart';
import 'user_agent_util.dart';

/// HTTP 请求工具类
/// 基于 Dio 封装，自动添加请求头
class HttpUtil {
  HttpUtil._();

  static HttpUtil? _instance;
  static dio_package.Dio? _dioInstance;

  /// 单例获取
  static HttpUtil get instance {
    _instance ??= HttpUtil._();
    return _instance!;
  }

  /// 获取 Dio 实例
  static dio_package.Dio get dio {
    if (_dioInstance == null) {
      _dioInstance = dio_package.Dio();
      _dioInstance!.options = dio_package.BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
      );

      // 添加请求拦截器，自动添加请求头
      _dioInstance!.interceptors.add(
        dio_package.InterceptorsWrapper(
          onRequest: (options, handler) async {
            // 所有请求头都必须携带
            options.headers['App-Channel'] = AppConfig.flavor;
            options.headers['app'] = AppConfig.app;

            // 获取当前语言环境
            final localeService = Get.find<LocaleService>();
            final locale = localeService.currentLocale;
            options.headers['Accept-Language'] =
                '${locale.languageCode}_${locale.countryCode ?? ''}';

            // 添加 User-Agent（如果用户已同意隐私政策）
            final userAgent = await UserAgentUtil.buildUserAgent();
            if (userAgent.isNotEmpty) {
              options.headers['User-Agent'] = userAgent;
            }

            return handler.next(options);
          },
        ),
      );
    }
    return _dioInstance!;
  }

  /// GET 请求
  Future<dio_package.Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    dio_package.Options? options,
    dio_package.CancelToken? cancelToken,
    dio_package.ProgressCallback? onReceiveProgress,
  }) async {
    return dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// POST 请求
  Future<dio_package.Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    dio_package.Options? options,
    dio_package.CancelToken? cancelToken,
    dio_package.ProgressCallback? onSendProgress,
    dio_package.ProgressCallback? onReceiveProgress,
  }) async {
    return dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// PUT 请求
  Future<dio_package.Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    dio_package.Options? options,
    dio_package.CancelToken? cancelToken,
    dio_package.ProgressCallback? onSendProgress,
    dio_package.ProgressCallback? onReceiveProgress,
  }) async {
    return dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// DELETE 请求
  Future<dio_package.Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    dio_package.Options? options,
    dio_package.CancelToken? cancelToken,
  }) async {
    return dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// PATCH 请求
  Future<dio_package.Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    dio_package.Options? options,
    dio_package.CancelToken? cancelToken,
    dio_package.ProgressCallback? onSendProgress,
    dio_package.ProgressCallback? onReceiveProgress,
  }) async {
    return dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }
}
