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

  /// 网络错误提示消息的键（用于国际化）
  /// 如果为 null，则使用默认消息
  final String? networkErrorKey;

  /// 提示标题的键（用于国际化）
  /// 如果为 null，则使用默认标题
  final String? tipTitleKey;

  /// 错误消息显示回调
  /// 如果为 null，则不显示错误提示
  final void Function(String title, String message)? onError;

  HttpConfig({
    required this.baseUrl,
    this.staticHeaders,
    this.dynamicHeaderBuilder,
    this.networkErrorKey,
    this.tipTitleKey,
    this.onError,
  });
}
