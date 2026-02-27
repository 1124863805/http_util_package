import 'package:flutter/material.dart';
import 'package:dio_http_util/http_util.dart';
import '../tyme4/tyme.dart';

/// HTTP 演示：GET 请求、公历/农历/藏历
class HttpDemoPage extends StatefulWidget {
  const HttpDemoPage({super.key});

  @override
  State<HttpDemoPage> createState() => _HttpDemoPageState();
}

class _HttpDemoPageState extends State<HttpDemoPage> {
  String _result = '点击按钮发送 GET 请求';

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
    final solarDay = SolarDay.fromYmd(2026, 2, 25);
    setState(() {
      _result =
          '$solarDay\n${solarDay.getLunarDay()}\n${solarDay.getRabByungDay()}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HTTP 演示'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 24),
          _ResultPanel(result: _result),
        ],
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  final String result;

  const _ResultPanel({required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '响应结果',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: SingleChildScrollView(
                child: SelectableText(result, style: const TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
