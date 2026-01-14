import 'package:get/get.dart';
import 'package:dio_http_util/http_util.dart';

class ChatController extends GetxController {
  // 单个连接演示
  final sseMessage = ''.obs; // SSE 消息内容
  final isSSEConnected = false.obs; // SSE 连接状态

  // 多个连接演示
  final sseMessage1 = ''.obs; // 连接1的消息内容
  final sseMessage2 = ''.obs; // 连接2的消息内容
  final sseMessage3 = ''.obs; // 连接3的消息内容
  final isMultipleSSEConnected = false.obs; // 多连接状态

  SSEManager? _sseManager; // SSE 连接管理器（支持多连接）

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

  /// 单个连接演示：连接 SSE 并发送问题
  Future<void> connectSSE(String question) async {
    if (_sseManager == null) {
      _sseManager = http.sseManager();
    }

    try {
      isSSEConnected.value = true;
      sseMessage.value = ''; // 清空之前的消息

      // 使用 SSE 管理器建立单个连接
      await _sseManager!.connect(
        id: 'chat', // 连接唯一标识符
        path: '/ai/chat/stream',
        method: 'POST',
        data: {'question': question},
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

  /// 单个连接演示：断开 SSE 连接
  Future<void> disconnectSSE() async {
    if (_sseManager != null) {
      await _sseManager!.disconnect('chat');
    }
    isSSEConnected.value = false;
  }

  /// 多个连接演示：同时建立多个 SSE 连接（都调用同一个接口）
  Future<void> connectMultipleSSE() async {
    if (_sseManager == null) {
      _sseManager = http.sseManager();
    }

    try {
      isMultipleSSEConnected.value = true;
      // 清空所有消息
      sseMessage1.value = '';
      sseMessage2.value = '';
      sseMessage3.value = '';

      // 连接 1：调用 /ai/chat/stream，八字问题1
      await _sseManager!.connect(
        id: 'chat1',
        path: '/ai/chat/stream',
        method: 'POST',
        data: {'question': '什么是八字？'},
        onData: (event) {
          sseMessage1.value += event.data;
        },
        onError: (error) {
          print('❌ 连接1错误: $error');
          Get.snackbar(
            '错误',
            '连接1错误: $error',
            snackPosition: SnackPosition.BOTTOM,
          );
        },
      );

      // 连接 2：调用 /ai/chat/stream，八字问题2
      await _sseManager!.connect(
        id: 'chat2',
        path: '/ai/chat/stream',
        method: 'POST',
        data: {'question': '八字如何看财运？'},
        onData: (event) {
          sseMessage2.value += event.data;
        },
        onError: (error) {
          print('❌ 连接2错误: $error');
          Get.snackbar(
            '错误',
            '连接2错误: $error',
            snackPosition: SnackPosition.BOTTOM,
          );
        },
      );

      // 连接 3：调用 /ai/chat/stream，八字问题3
      await _sseManager!.connect(
        id: 'chat3',
        path: '/ai/chat/stream',
        method: 'POST',
        data: {'question': '八字中的五行是什么？'},
        onData: (event) {
          sseMessage3.value += event.data;
        },
        onError: (error) {
          print('❌ 连接3错误: $error');
          Get.snackbar(
            '错误',
            '连接3错误: $error',
            snackPosition: SnackPosition.BOTTOM,
          );
        },
      );
    } catch (e) {
      print('❌ 多连接失败: $e');
      isMultipleSSEConnected.value = false;
      Get.snackbar('错误', '多连接失败: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// 多个连接演示：断开所有连接
  Future<void> disconnectMultipleSSE() async {
    if (_sseManager != null) {
      await _sseManager!.disconnectAll();
    }
    isMultipleSSEConnected.value = false;
  }

  /// 获取连接数量（用于显示）
  int get connectionCount => _sseManager?.connectionCount ?? 0;
}
