import 'package:flutter/material.dart';
import 'response_parser.dart';
import 'parsers/standard_response_parser.dart';
import 'request_deduplicator.dart';

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

  /// 401 未授权回调（专门处理 401 错误）
  /// 
  /// 包层面会自动对 401 进行去重处理，在 [errorDeduplicationWindow] 时间窗口内
  /// 只会调用一次此回调，避免并发请求时重复处理。
  /// 
  /// 如果设置了此回调，401 错误将优先使用此回调，不再调用 [onFailure]。
  /// 
  /// 示例：
  /// ```dart
  /// on401Unauthorized: () {
  ///   AuthUtil.clearLoginInfo();
  ///   Get.offAllNamed(Routes.LOGIN);
  ///   Get.snackbar('提示', '登录已过期，请重新登录');
  /// }
  /// ```
  final VoidCallback? on401Unauthorized;

  /// 错误消息显示回调（全局默认错误处理）
  /// 如果为 null，则不显示错误提示
  /// 
  /// 回调参数：
  /// - [httpStatusCode] HTTP 状态码（如 200, 404, 500 等，可能为 null）
  /// - [errorCode] 业务错误码（可能为 null，取决于 Response 实现）
  /// - [message] 错误消息（可能是国际化键，需要在回调中自行翻译）
  /// 
  /// 注意：
  /// - 如果用户使用了链式调用的 onFailure，此回调不会被调用（优先级：链式调用的 onFailure > 全局的 onFailure）
  /// - 如果设置了 [on401Unauthorized]，401 错误不会调用此回调
  /// 
  /// 示例：
  /// ```dart
  /// onFailure: (httpStatusCode, errorCode, message) {
  ///   print('HTTP 状态码: $httpStatusCode, 业务错误码: $errorCode, 错误消息: $message');
  ///   if (errorCode == 1001) {
  ///     // 处理业务错误码 1001
  ///   }
  /// }
  /// ```
  final void Function(int? httpStatusCode, int? errorCode, String message)? onFailure;

  /// 错误去重时间窗口（默认 5 秒）
  /// 
  /// 在时间窗口内，相同错误码的错误只会处理一次。
  /// 主要用于 401 错误的去重，避免并发请求时重复跳转登录页。
  /// 
  /// 示例：
  /// ```dart
  /// errorDeduplicationWindow: Duration(seconds: 5), // 5 秒内相同错误码只处理一次
  /// ```
  final Duration errorDeduplicationWindow;

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

  /// Context 获取器（可选）
  /// 如果提供，工具包会自动使用加载提示功能
  ///
  /// 示例（使用 GetX）：
  /// ```dart
  /// contextGetter: () => Get.context
  /// ```
  ///
  /// 示例（使用 Navigator）：
  /// ```dart
  /// final navigatorKey = GlobalKey<NavigatorState>();
  /// // 在 MaterialApp 中设置 navigatorKey: navigatorKey
  /// contextGetter: () => navigatorKey.currentContext
  /// ```
  final BuildContext? Function()? contextGetter;

  /// 自定义加载提示 Widget 构建器（可选）
  /// 如果提供，将使用自定义的加载提示 UI
  /// 如果不提供，将使用工具包内置的默认实现
  ///
  /// [context] 由 contextGetter 获取的 BuildContext
  /// 返回 Widget，工具包会将其显示在 Overlay 中
  ///
  /// 示例：
  /// ```dart
  /// loadingWidgetBuilder: (context) => MyCustomLoadingWidget(),
  /// ```
  final Widget Function(BuildContext context)? loadingWidgetBuilder;

  /// 请求去重/防抖配置（可选）
  /// 如果提供，将启用请求去重/防抖功能
  ///
  /// 示例：
  /// ```dart
  /// deduplicationConfig: DeduplicationConfig(
  ///   mode: DeduplicationMode.deduplication,
  ///   debounceDelay: Duration(milliseconds: 300),
  /// ),
  /// ```
  final DeduplicationConfig? deduplicationConfig;

  /// 请求队列配置（可选）
  /// 如果提供，将启用请求队列管理功能
  ///
  /// 示例：
  /// ```dart
  /// queueConfig: QueueConfig(
  ///   maxConcurrency: 5,
  ///   enabled: true,
  /// ),
  /// ```
  final QueueConfig? queueConfig;

  /// 服务 baseUrl 映射（可选）
  /// key: 服务名称（如 'files', 'cdn'），value: 对应的 baseUrl
  ///
  /// 示例：
  /// ```dart
  /// serviceBaseUrls: {
  ///   'files': 'https://files.example.com',
  ///   'cdn': 'https://cdn.example.com',
  ///   'third-party': 'https://third-party.com/api',
  /// }
  /// ```
  ///
  /// 使用方式：
  /// ```dart
  /// // 使用默认 baseUrl
  /// await http.send(method: hm.get, path: '/users');
  ///
  /// // 使用服务
  /// await http.send(method: hm.post, path: '/upload', service: 'files');
  ///
  /// // 直接指定 baseUrl（最高优先级）
  /// await http.send(
  ///   method: hm.get,
  ///   path: '/data',
  ///   baseUrl: 'https://custom.example.com',
  /// );
  /// ```
  final Map<String, String>? serviceBaseUrls;

  HttpConfig({
    required this.baseUrl,
    ResponseParser? responseParser, // 可选参数，默认使用 StandardResponseParser
    this.staticHeaders,
    this.dynamicHeaderBuilder,
    this.networkErrorKey,
    this.on401Unauthorized,
    this.onFailure,
    this.errorDeduplicationWindow = const Duration(seconds: 5),
    this.enableLogging = false,
    this.logPrintBody = true,
    this.logMode = LogMode.complete,
    this.logShowRequestHint = true,
    this.contextGetter,
    this.loadingWidgetBuilder,
    this.deduplicationConfig,
    this.queueConfig,
    this.serviceBaseUrls,
  }) : responseParser = responseParser ?? StandardResponseParser();
}

/// 请求去重/防抖配置
class DeduplicationConfig {
  /// 去重模式
  final DeduplicationMode mode;

  /// 防抖延迟时间（仅在 debounce 模式下有效）
  final Duration debounceDelay;

  /// 节流间隔时间（仅在 throttle 模式下有效）
  final Duration throttleInterval;

  DeduplicationConfig({
    this.mode = DeduplicationMode.deduplication,
    this.debounceDelay = const Duration(milliseconds: 300),
    this.throttleInterval = const Duration(milliseconds: 300),
  });
}

/// 请求队列配置
class QueueConfig {
  /// 最大并发数（默认 10）
  final int maxConcurrency;

  /// 是否启用队列（默认 true）
  final bool enabled;

  QueueConfig({
    this.maxConcurrency = 10,
    this.enabled = true,
  });
}
