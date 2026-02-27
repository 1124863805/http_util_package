import 'package:flutter/material.dart';
import 'package:dio_http_util/http_util.dart';
import 'tyme4/tyme.dart';
import 'calendar/calendar.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
  runApp(const MyApp());
}

/// Demo parser: 2xx as success, body as data (see README_EN.md Custom Response Parser)
class _DemoResponseParser implements ResponseParser {
  @override
  Response<T> parse<T>(RawHttpResponse raw) {
    final ok =
        raw.statusCode != null &&
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
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  String _result = '点击按钮发送 GET 请求';
  final _calendarController = PerpetualCalendarController();

  Future<void> _sendRequest() async {
    final response = await http.send(
      method: hm.get,
      isLoading: true,
      path: '/get',
      queryParameters: {'demo': 'dio_http_util'},
    );
    if (!mounted) return;
    setState(() {
      _result = response.isSuccess
          ? '成功\n${response.getData()}'
          : '失败: ${response.errorMessage}';
    });
  }

  void _runTyme4Demo() {
    SolarDay solarDay = SolarDay.fromYmd(2026, 2, 25);
    setState(() {
      _result =
          '$solarDay\n${solarDay.getLunarDay()}\n${solarDay.getRabByungDay()}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('dio_http_util Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: _sendRequest,
            child: const Text('发送 GET 请求'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _runTyme4Demo,
            child: const Text('公历/农历/藏历 Demo'),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => _calendarController.toggleCollapsed(),
            icon: const Icon(Icons.unfold_more, size: 18),
            label: const Text('收起/展开日历'),
          ),
          PerpetualCalendar(controller: _calendarController),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: SingleChildScrollView(
              child: SelectableText(
                _result,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
