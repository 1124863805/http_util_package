import 'package:get/get.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:dio_http_util/http_util.dart' as http_util;
import '../config/app_config.dart';
import '../services/locale_service.dart';
import 'user_agent_util.dart';
import 'auth_util.dart';
import '../../generated/locale_keys.g.dart';
// 不再需要导入 standard_response_parser.dart，因为默认使用它

/// HTTP 工具类适配器
/// 用于在项目中配置独立的 http_util 包
class HttpAdapter {
  /// 初始化 HTTP 工具类配置
  static void init() {
    http_util.HttpUtil.configure(
      http_util.HttpConfig(
        baseUrl: 'https://api.holos.hk/v1',
        // responseParser 可选，不传递则使用默认的 StandardResponseParser
        // responseParser: StandardResponseParser(), // 如果需要自定义解析器，可以传递
        staticHeaders: {'App-Channel': AppConfig.flavor, 'app': AppConfig.app},
        dynamicHeaderBuilder: () async {
          final headers = <String, String>{};

          // Accept-Language
          try {
            final localeService = Get.find<LocaleService>();
            final locale = localeService.currentLocale;
            headers['Accept-Language'] =
                '${locale.languageCode}_${locale.countryCode ?? ''}';
          } catch (e) {
            // LocaleService 未找到时使用默认值
            headers['Accept-Language'] = 'zh_CN';
          }

          // User-Agent
          final userAgent = await UserAgentUtil.buildUserAgent();
          if (userAgent.isNotEmpty) {
            headers['User-Agent'] = userAgent;
          }

          // Authorization
          final accessToken = AuthUtil.getAccessToken();
          if (accessToken != null && accessToken.isNotEmpty) {
            headers['Authorization'] = 'Bearer $accessToken';
          }

          return headers;
        },
        networkErrorKey: LocaleKeys.network_error_retry,
        onError: (String message) {
          final context = Get.context;
          if (context != null) {
            // message 可能是国际化键，需要翻译
            // 如果传入的是键，则翻译；如果是文本，则直接使用
            final titleText = context.tr(LocaleKeys.tip);
            final messageText = context.tr(message);
            Get.snackbar(
              titleText,
              messageText,
              snackPosition: SnackPosition.BOTTOM,
            );
          }
        },
        // 启用日志打印
        enableLogging: true,
        logPrintBody: true,
      ),
    );
  }
}
