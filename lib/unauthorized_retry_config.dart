/// 登录态失效后的「刷新 token + 自动重试原请求」策略（包内**不写死**任何业务码或路径）。
///
/// 由 [HttpConfig.unauthorizedRetry] 启用。典型场景：HTTP **401**，或 JSON `code` 命中
/// [sessionExpiredBusinessCode]（若配置）。
///
/// **并发**：[refreshAccessToken] 可能被并行调用，应用侧须自行合并为单次刷新。
class UnauthorizedRetryConfig {
  const UnauthorizedRetryConfig({
    required this.refreshAccessToken,
    this.sessionExpiredBusinessCode,
    this.excludedPathPrefixes = const [],
    this.maxRetries = 1,
    this.onRefreshFailed,
  });

  /// 执行刷新；返回 `true` 表示新凭据已就绪，下一次网络往返会使用新头（见 [HttpConfig.dynamicHeaderBuilder]）。
  final Future<bool> Function() refreshAccessToken;

  /// 视为「会话过期」、需要刷新后重试的**业务码**（与 HTTP 状态码独立，由 [ResponseParser] 写入 [Response.errorCode]）。
  /// - **`null`**（默认）：**仅**当 HTTP 状态码为 **401** 时触发刷新重试。
  /// - **非 null**：HTTP 401 **或** `errorCode` 等于该值时触发（例如部分网关仍返回 200 + body `code`）。
  final int? sessionExpiredBusinessCode;

  /// 不触发刷新重试的 path **前缀**；由调用方按自身路由约定填写（包内默认为空，不排除任何路径）。
  final List<String> excludedPathPrefixes;

  /// 单次 [HttpUtil.send] 内最多**额外**重试次数（不含首次请求）。
  final int maxRetries;

  /// [refreshAccessToken] 返回 `false` 时调用（抛错由外层 [send] 捕获为网络错误，不经过此处）。
  /// 调用后，同一次响应在 [HttpUtil.send] 内**不会**再触发 [HttpConfig.on401Unauthorized] 与全局 [HttpConfig.onFailure]
  ///（当响应仍为「未授权形态」时），避免与插件原有 401 处理重复。
  final Future<void> Function()? onRefreshFailed;
}
