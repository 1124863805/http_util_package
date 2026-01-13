import 'response_parser.dart';
import 'parsers/standard_response_parser.dart';

/// 日志打印模式
enum LogMode {
  /// 完整链路模式（推荐）- 响应时一起打印请求+响应+耗时
  /// 优点：请求-响应完美关联，并发友好，自动显示耗时
  complete,

  /// 实时模式 - 请求和响应分别打印
  /// 优点：实时性好，立即看到请求发出
  realTime,

  /// 简要模式 - 只打印关键信息
  /// 优点：日志简洁，适合生产环境
  brief,
}

/// HTTP 工具类配置
/// 用于配置请求头、错误处理等
class HttpConfig {
  /// 基础 URL
  final String baseUrl;

  /// 静态请求头（固定值）
  final Map<String, String>? staticHeaders;

  /// 动态请求头构建器（每次请求时调用）
  /// 返回的 Map 会合并到请求头中
  final Future<Map<String, String>> Function()? dynamicHeaderBuilder;

  /// 响应解析器（可选，默认使用 StandardResponseParser）
  /// 用于将 Dio Response 转换为用户定义的 Response
  ///
  /// 如果不提供，将使用默认的 StandardResponseParser（处理标准结构：{code: int, message: String, data: dynamic}）
  ///
  /// 可以使用 PathBasedResponseParser 来支持不同路径使用不同解析器
  ///
  /// 示例：
  /// ```dart
  /// // 使用默认解析器（不传递 responseParser）
  /// HttpConfig(baseUrl: 'https://api.example.com')
  ///
  /// // 或自定义解析器
  /// responseParser: StandardResponseParser()
  /// ```
  ///
  /// 或使用路径匹配：
  /// ```dart
  /// responseParser: PathBasedResponseParser(
  ///   matchers: [
  ///     PathMatcher(pattern: RegExp(r'^/api/v1/.*'), parser: V1Parser()),
  ///     PathMatcher(pattern: RegExp(r'^/api/v2/.*'), parser: V2Parser()),
  ///   ],
  ///   defaultParser: StandardResponseParser(),
  /// )
  /// ```
  final ResponseParser responseParser;

  /// 网络错误提示消息的键（用于国际化）
  /// 如果为 null，则使用默认消息
  final String? networkErrorKey;

  /// 错误消息显示回调
  /// 如果为 null，则不显示错误提示
  /// [message] 可能是国际化键，需要在回调中自行翻译
  final void Function(String message)? onError;

  /// 是否启用日志打印（默认 false）
  /// 启用后会自动打印请求和响应信息
  final bool enableLogging;

  /// 日志打印级别
  /// - true: 打印请求和响应（包含 body）
  /// - false: 只打印请求和响应（不包含 body）
  final bool logPrintBody;

  /// 日志打印模式（默认 complete）
  /// - LogMode.complete: 完整链路模式（推荐）- 响应时一起打印请求+响应+耗时
  /// - LogMode.realTime: 实时模式 - 请求和响应分别打印
  /// - LogMode.brief: 简要模式 - 只打印关键信息
  final LogMode logMode;

  /// 是否在请求时显示简要提示（仅在 complete 模式下有效，默认 true）
  /// 如果为 true，请求时会打印一行简要信息，如 "→ POST /api/login"
  final bool logShowRequestHint;

  HttpConfig({
    required this.baseUrl,
    ResponseParser? responseParser, // 可选参数，默认使用 StandardResponseParser
    this.staticHeaders,
    this.dynamicHeaderBuilder,
    this.networkErrorKey,
    this.onError,
    this.enableLogging = false,
    this.logPrintBody = true,
    this.logMode = LogMode.complete,
    this.logShowRequestHint = true,
  }) : responseParser = responseParser ?? StandardResponseParser();
}
