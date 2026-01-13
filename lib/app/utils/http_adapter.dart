import 'package:get/get.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:dio_http_util/http_util.dart' as http_util;
import '../config/app_config.dart';
import '../services/locale_service.dart';
import 'user_agent_util.dart';
import 'auth_util.dart';
import '../../generated/locale_keys.g.dart';

/// HTTP 工具类适配器
/// 用于在项目中配置独立的 http_util 包
class HttpAdapter {
  /// 初始化 HTTP 工具类配置
  static void init() {
    http_util.HttpUtil.configure(
      http_util.HttpConfig(
        baseUrl: 'https://api.holos.hk/v1',
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
        tipTitleKey: LocaleKeys.tip,
        onError: (title, message) {
          final context = Get.context;
          if (context != null) {
            final titleText = context.tr(LocaleKeys.tip);
            final messageText = message;
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
