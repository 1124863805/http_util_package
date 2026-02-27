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
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  void _onDateChanged(DateTime date) {
    setState(() => _selectedDate = date);
    _calendarController.goToDate(date);
  }

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
          _DateSelector(
            date: _selectedDate,
            onChanged: _onDateChanged,
          ),
          TextButton.icon(
            onPressed: () => _calendarController.toggleCollapsed(),
            icon: const Icon(Icons.unfold_more, size: 18),
            label: const Text('收起/展开日历'),
          ),
          PerpetualCalendar(
            controller: _calendarController,
            selectedDate: _selectedDate,
            onDateSelected: _onDateChanged,
          ),
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

class _DateSelector extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  const _DateSelector({
    required this.date,
    required this.onChanged,
  });

  static const int _baseYear = 1900;
  static const int _endYear = 2099;

  int _dayCount(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('快速切换：', style: theme.textTheme.bodyMedium),
          const SizedBox(width: 8),
          _Dropdown<int>(
            value: date.year,
            items: List.generate(
              _endYear - _baseYear + 1,
              (i) => DropdownMenuItem(value: _baseYear + i, child: Text('${_baseYear + i}年')),
            ),
            onChanged: (v) {
              if (v != null) {
                final d = date.day.clamp(1, _dayCount(v, date.month));
                onChanged(DateTime(v, date.month, d));
              }
            },
          ),
          const SizedBox(width: 8),
          _Dropdown<int>(
            value: date.month,
            items: List.generate(
              12,
              (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}月')),
            ),
            onChanged: (v) {
              if (v != null) {
                final d = date.day.clamp(1, _dayCount(date.year, v));
                onChanged(DateTime(date.year, v, d));
              }
            },
          ),
          const SizedBox(width: 8),
          _Dropdown<int>(
            value: date.day,
            items: List.generate(
              _dayCount(date.year, date.month),
              (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}日')),
            ),
            onChanged: (v) {
              if (v != null) onChanged(DateTime(date.year, date.month, v));
            },
          ),
        ],
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _Dropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isDense: true,
        ),
      ),
    );
  }
}
