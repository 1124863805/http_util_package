// 导出所有公共 API
export 'http_config.dart';
export 'http_method.dart';
export 'response.dart'; // Response 接口（必需）
export 'api_response.dart'; // ApiResponse 实现示例（可选）
export 'http_util_impl.dart';
export 'log_interceptor.dart';
export 'response_parser.dart';
export 'parsers/standard_response_parser.dart'; // 默认响应解析器
export 'upload_file.dart'; // 文件上传辅助类
export 'download_response.dart'; // 文件下载响应类
export 'sse/sse_event.dart'; // SSE 事件模型
export 'sse/sse_client.dart'; // SSE 客户端
export 'sse/sse_connection.dart'; // SSE 连接封装（自动管理订阅）
export 'sse/sse_manager.dart'; // SSE 连接管理器（多连接管理）

// 导出 Dio 类型，方便直接使用
// 注意：隐藏 Dio 的 Response 和 LogInterceptor，使用我们自己的实现
export 'package:dio/dio.dart' hide Response, LogInterceptor;
export 'package:dio/dio.dart'
    show Dio, Options, CancelToken, ProgressCallback, FormData;
