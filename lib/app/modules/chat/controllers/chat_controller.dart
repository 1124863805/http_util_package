import 'package:get/get.dart';
import 'package:dio_http_util/http_util.dart';

class ChatController extends GetxController {
  final sseMessage = ''.obs;
  final isSSEConnected = false.obs;

  final _sseManager = http.sseManager();
  final _token =
      'eyJhbGciOiJSUzI1NiIsImtpZCI6ImIyNjM4YTkzLTAwZjgtNDAwZi04NTEyLWJjMDQ3MTYyZDU3ZiJ9.eyJpc3MiOiJodHRwczovL2FwaS5jb3plLmNuIiwiYXVkIjpbImRqdDgwaGJaekpJaUdIVE9WaFYyZXlNWGNQNmprd0JkIl0sImV4cCI6ODIxMDI2Njg3Njc5OSwiaWF0IjoxNzY4NTMxODUyLCJzdWIiOiJzcGlmZmU6Ly9hcGkuY296ZS5jbi93b3JrbG9hZF9pZGVudGl0eS9pZDo3NTk1NTAyMzQ4NjcyMTcyMDQyIiwic3JjIjoiaW5ib3VuZF9hdXRoX2FjY2Vzc190b2tlbl9pZDo3NTk1Nzg2NDY3MTc2MDg3NjAzIn0.YUFn-2aMmjEN6k4YXlQr3vWgfIvMtN3nqI1mMWGWikbYVybmzQEoRl1eMtO53EIOklHYvvcicDFxqCH2G5Zz4Zjd91LjpAjiTTLd2RqRI9lgke5NsywbHl8bte2_z0ehWSvmXnhbknSQ8EK01tWxzcfU48GIfA9HmyNYgI_tSn61a6bd_3cYOmvCvMyuAzkEcKTPsMgt0gyeGsWaPSYgdS4H31emaWG_HuVk5_kiQRlWU9ooIVFSxpwyTo_E_R5oEzRxNrdtl01qPq3W87-k9Ubjw0og-cpcMp2M43VCinP05LvDRtdrwaNM3WG0Dfw_6oysE7sy6M7-8QKbEqq10Q';

  @override
  void onClose() {
    _sseManager.disconnectAll();
    super.onClose();
  }

  Future<void> connectSSE(String question) async {
    try {
      isSSEConnected.value = true;
      sseMessage.value = '';

      await _sseManager.connect(
        id: 'chat',
        baseUrl: 'https://859vy9xjm9.coze.site',
        path: '/stream_run',
        method: 'POST',
        data: {
          'content': {
            'query': {
              'prompt': [
                {
                  'type': 'text',
                  'content': {'text': question},
                },
              ],
            },
          },
          'type': 'query',
          'session_id': 'qxJchuPEtGl3vGOBWJrwV',
          'project_id': 7595495638419341362,
        },
        headers: {'Authorization': 'Bearer $_token'},
        onData: (event) => sseMessage.value += event.data,
        onError: (error) {
          isSSEConnected.value = false;
          Get.snackbar(
            '错误',
            'SSE 连接错误: $error',
            snackPosition: SnackPosition.BOTTOM,
          );
        },
        onDone: () => isSSEConnected.value = false,
      );
    } catch (e) {
      isSSEConnected.value = false;
      Get.snackbar('错误', 'SSE 连接失败: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> disconnectSSE() async {
    await _sseManager.disconnect('chat');
    isSSEConnected.value = false;
  }
}
