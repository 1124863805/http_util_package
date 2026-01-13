import 'package:dio/dio.dart' as dio_package;
import 'package:get/get.dart';
import 'package:easy_localization/easy_localization.dart';
import '../config/app_config.dart';
import '../services/locale_service.dart';
import 'user_agent_util.dart';
import 'auth_util.dart';
import 'api_response.dart';
import '../../generated/locale_keys.g.dart';

/// HTTP 请求方法常量
class hm {
  hm._();
  static const String get = 'GET';
  static const String post = 'POST';
  static const String put = 'PUT';
  static const String delete = 'DELETE';
  static const String patch = 'PATCH';
}

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
        baseUrl: 'https://api.holos.hk/v1',
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

            // 添加 Authorization 头（如果已登录）
            final accessToken = AuthUtil.getAccessToken();
            if (accessToken != null && accessToken.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $accessToken';
            }

            return handler.next(options);
          },
          onResponse: (response, handler) {
            // 处理 401 错误（未授权，清除登录信息）
            if (response.statusCode == 401) {
              AuthUtil.clearLoginInfo();
            }
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
        throw ArgumentError('不支持的请求方式: $method，请使用 hm 常量（hm.get、hm.post 等）');
    }
  }
}

/// HttpUtil 扩展方法
/// 提供安全调用方法，自动处理异常和错误提示
extension HttpUtilSafeCall on HttpUtil {
  /// 处理网络错误（统一提示）
  ApiResponse<T> _handleNetworkError<T>() {
    final context = Get.context;
    final errorMessage =
        context?.tr(LocaleKeys.network_error_retry) ?? '网络错误，请稍后重试！';

    if (context != null) {
      Get.snackbar(
        context.tr(LocaleKeys.tip),
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
      );
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
final http = HttpUtil.instance;
