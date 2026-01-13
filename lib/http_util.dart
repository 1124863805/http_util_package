// 导出所有公共 API
export 'http_config.dart';
export 'http_method.dart';
export 'response.dart'; // Response 接口（必需）
export 'api_response.dart'; // ApiResponse 实现示例（可选）
export 'http_util_impl.dart';
export 'log_interceptor.dart';
export 'response_parser.dart';
export 'parsers/standard_response_parser.dart'; // 默认响应解析器

// 导出 Dio 类型，方便直接使用
// 注意：隐藏 Dio 的 Response 和 LogInterceptor，使用我们自己的实现
export 'package:dio/dio.dart' hide Response, LogInterceptor;
export 'package:dio/dio.dart'
    show Dio, Options, CancelToken, ProgressCallback, FormData;
