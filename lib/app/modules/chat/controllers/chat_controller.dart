import 'package:get/get.dart';
import 'package:dio_http_util/http_util.dart';

class ChatController extends GetxController {
  final sseMessage = ''.obs; // SSE 消息内容
  final isSSEConnected = false.obs; // SSE 连接状态

  SSEManager? _sseManager; // SSE 连接管理器

  // Coze API 配置
  static const String _cozeBaseUrl = 'https://859vy9xjm9.coze.site';
  static const String _cozePath = '/stream_run';
  static const String _cozeToken =
      'eyJhbGciOiJSUzI1NiIsImtpZCI6ImIyNjM4YTkzLTAwZjgtNDAwZi04NTEyLWJjMDQ3MTYyZDU3ZiJ9.eyJpc3MiOiJodHRwczovL2FwaS5jb3plLmNuIiwiYXVkIjpbImRqdDgwaGJaekpJaUdIVE9WaFYyZXlNWGNQNmprd0JkIl0sImV4cCI6ODIxMDI2Njg3Njc5OSwiaWF0IjoxNzY4NTMxODUyLCJzdWIiOiJzcGlmZmU6Ly9hcGkuY296ZS5jbi93b3JrbG9hZF9pZGVudGl0eS9pZDo3NTk1NTAyMzQ4NjcyMTcyMDQyIiwic3JjIjoiaW5ib3VuZF9hdXRoX2FjY2Vzc190b2tlbl9pZDo3NTk1Nzg2NDY3MTc2MDg3NjAzIn0.YUFn-2aMmjEN6k4YXlQr3vWgfIvMtN3nqI1mMWGWikbYVybmzQEoRl1eMtO53EIOklHYvvcicDFxqCH2G5Zz4Zjd91LjpAjiTTLd2RqRI9lgke5NsywbHl8bte2_z0ehWSvmXnhbknSQ8EK01tWxzcfU48GIfA9HmyNYgI_tSn61a6bd_3cYOmvCvMyuAzkEcKTPsMgt0gyeGsWaPSYgdS4H31emaWG_HuVk5_kiQRlWU9ooIVFSxpwyTo_E_R5oEzRxNrdtl01qPq3W87-k9Ubjw0og-cpcMp2M43VCinP05LvDRtdrwaNM3WG0Dfw_6oysE7sy6M7-8QKbEqq10Q';
  static const String _sessionId = 'qxJchuPEtGl3vGOBWJrwV';
  static const int _projectId = 7595495638419341362;

  @override
  void onInit() {
    super.onInit();
    // 创建 SSE 管理器
    _sseManager = http.sseManager();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    // 断开所有 SSE 连接
    _sseManager?.disconnectAll();
    super.onClose();
  }

  /// 连接 SSE 并发送问题
  Future<void> connectSSE(String question) async {
    if (_sseManager == null) {
      _sseManager = http.sseManager();
    }

    try {
      isSSEConnected.value = true;
      sseMessage.value = ''; // 清空之前的消息

      // 构建请求体（按照 Coze API 格式）
      final requestData = {
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
        'session_id': _sessionId,
        'project_id': _projectId,
      };

      // 使用 SSE 管理器建立连接
      await _sseManager!.connect(
        id: 'chat', // 连接唯一标识符
        baseUrl: _cozeBaseUrl,
        path: _cozePath,
        method: 'POST',
        data: requestData,
        headers: {'Authorization': 'Bearer $_cozeToken'},
        onData: (event) {
          // 累积消息内容
          sseMessage.value += event.data;
        },
        onError: (error) {
          isSSEConnected.value = false;
          Get.snackbar(
            '错误',
            'SSE 连接错误: $error',
            snackPosition: SnackPosition.BOTTOM,
          );
        },
        onDone: () {
          isSSEConnected.value = false;
        },
      );
    } catch (e) {
      isSSEConnected.value = false;
      Get.snackbar('错误', 'SSE 连接失败: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// 断开 SSE 连接
  Future<void> disconnectSSE() async {
    if (_sseManager != null) {
      await _sseManager!.disconnect('chat');
    }
    isSSEConnected.value = false;
  }
}
