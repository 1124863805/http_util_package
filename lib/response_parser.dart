import 'response.dart';

/// 原始 HTTP 响应（包内封装，不暴露底层实现）
/// 解析器仅依赖此类型，调用方无需依赖 Dio
class RawHttpResponse {
  /// HTTP 状态码
  final int? statusCode;

  /// 响应体
  final dynamic data;

  /// 请求路径（用于 PathBasedResponseParser 等按路径选择解析器）
  final String path;

  const RawHttpResponse({
    required this.statusCode,
    required this.data,
    required this.path,
  });
}

/// 响应解析器接口
/// 用户必须实现此接口来定义如何将原始 HTTP 响应转换为用户定义的 Response
///
/// 示例：
/// ```dart
/// class MyResponseParser implements ResponseParser {
///   @override
///   Response<T> parse<T>(RawHttpResponse raw) {
///     final data = raw.data as Map<String, dynamic>;
///     return MyResponse(
///       success: data['status'] == 'success',
///       error: data['error'] as String?,
///       payload: data['result'] as T?,
///     );
///   }
/// }
/// ```
abstract class ResponseParser {
  /// 解析响应
  /// [raw] 原始 HTTP 响应（statusCode、data、path）
  /// 返回用户定义的 Response，必须处理所有可能的响应结构
  Response<T> parse<T>(RawHttpResponse raw);
}

/// 路径匹配规则
/// 用于根据请求路径选择不同的解析器
class PathMatcher {
  /// 路径模式（支持正则表达式或字符串匹配）
  final Pattern pattern;

  /// 对应的解析器
  final ResponseParser parser;

  PathMatcher({
    required this.pattern,
    required this.parser,
  });

  /// 检查路径是否匹配
  bool matches(String path) {
    return pattern.allMatches(path).isNotEmpty;
  }
}

/// 路径匹配解析器
/// 根据请求路径选择不同的解析器
class PathBasedResponseParser implements ResponseParser {
  final List<PathMatcher> matchers;
  final ResponseParser defaultParser;

  PathBasedResponseParser({
    required this.matchers,
    required this.defaultParser,
  });

  @override
  Response<T> parse<T>(RawHttpResponse raw) {
    // 查找匹配的解析器
    for (final matcher in matchers) {
      if (matcher.matches(raw.path)) {
        return matcher.parser.parse<T>(raw);
      }
    }

    // 使用默认解析器
    return defaultParser.parse<T>(raw);
  }
}
