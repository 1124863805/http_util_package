import 'package:flutter/material.dart';
import 'package:dio_http_util/http_util.dart';

import 'pages/home_page.dart';
import 'widgets/privacy_agreement/privacy_agreement.dart';

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
      },
      child: const MyApp(),
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
