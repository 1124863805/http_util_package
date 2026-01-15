import 'package:dio/dio.dart' as dio_package;
import '../api_response.dart';
import '../response_parser.dart';

/// 标准响应解析器
/// 处理标准结构：{code: int, message: String, data: dynamic}
///
/// 使用示例：
/// ```dart
/// HttpUtil.configure(
///   HttpConfig(
///     baseUrl: 'https://api.example.com',
///     responseParser: StandardResponseParser(),
///   ),
/// );
/// ```
class StandardResponseParser implements ResponseParser {
  @override
  ApiResponse<T> parse<T>(dio_package.Response response) {
    if (response.data is! Map<String, dynamic>) {
      return ApiResponse<T>(
        code: -1,
        message: '响应格式错误',
        data: null,
        httpStatusCode: response.statusCode, // 传递 HTTP 状态码
      );
    }

    final data = response.data as Map<String, dynamic>;
    return ApiResponse<T>(
      code: (data['code'] as int?) ?? -1,
      message: (data['message'] as String?) ?? '',
      data: data['data'],
      httpStatusCode: response.statusCode, // 传递 HTTP 状态码
    );
  }
}
