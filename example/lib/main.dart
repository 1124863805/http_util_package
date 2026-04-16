import 'package:flutter/material.dart';
import 'package:dio_http_util/http_util.dart';

import 'pages/home_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    PrivacyGate(
      config: const PrivacyAgreementConfig(
        userAgreementUrl: 'https://download.laibuyi.com/agreement.html',
        privacyPolicyUrl: 'https://download.laibuyi.com/privacy.html',
      ),
      onAgreed: () async {
        await _simulateAndroidSdkInitAfterConsent();
        _configureDemoHttp();
      },
      child: const MyApp(),
    ),
  );
}

/// 模拟 Android 原生在「隐私同意」之后执行的初始化（主线程/异步任务混合，此处用延迟代替）。
Future<void> _simulateAndroidSdkInitAfterConsent() async {
  debugPrint('[Demo][Android] 用户已同意隐私 → 开始初始化 SDK（模拟）');
  // 模拟 Application.onCreate / MethodChannel / 厂商 SDK 异步就绪
  await Future<void>.delayed(const Duration(milliseconds: 1200));
  debugPrint('[Demo][Android] SDK 初始化完成 → 可安全发起网络与 HttpUtil 配置');
}

/// 与真实流程一致：SDK 就绪后再配置网络层（demo 使用 httpbin）。
void _configureDemoHttp() {
  HttpUtil.configure(
    HttpConfig(
      baseUrl: 'https://httpbin.org',
      responseParser: _DemoResponseParser(),
      enableLogging: true,
      contextGetter: () => navigatorKey.currentContext,
      onFailure: (httpStatusCode, errorCode, message) {
        debugPrint('请求失败: $message');
      },
    ),
  );
}

/// Demo parser: 2xx as success, body as data
class _DemoResponseParser implements ResponseParser {
  @override
  Response<T> parse<T>(RawHttpResponse raw) {
    final ok = raw.statusCode != null &&
        raw.statusCode! >= 200 &&
        raw.statusCode! < 300;
    return ApiResponse<T>(
      code: ok ? 0 : (raw.statusCode ?? -1),
      message: '',
      data: ok ? raw.data as T? : null,
      httpStatusCode: raw.statusCode,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'dio_http_util Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const HomePage(),
    );
  }
}
