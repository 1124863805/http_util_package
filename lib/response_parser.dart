import 'package:dio/dio.dart' as dio_package;
import 'response.dart';

/// 响应解析器接口
/// 用户必须实现此接口来定义如何将 Dio Response 转换为用户定义的 Response
///
/// 示例：
/// ```dart
/// class MyResponseParser implements ResponseParser {
///   @override
///   Response<T> parse<T>(dio_package.Response response) {
///     final data = response.data as Map<String, dynamic>;
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
  /// [response] Dio 的原始响应对象
  /// 返回用户定义的 Response，必须处理所有可能的响应结构
  Response<T> parse<T>(dio_package.Response response);
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
  Response<T> parse<T>(dio_package.Response response) {
    // 从请求选项中获取路径
    final path = response.requestOptions.path;

    // 查找匹配的解析器
    for (final matcher in matchers) {
      if (matcher.matches(path)) {
        return matcher.parser.parse<T>(response);
      }
    }

    // 使用默认解析器
    return defaultParser.parse<T>(response);
  }
}
