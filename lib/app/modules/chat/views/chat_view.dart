import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../generated/locale_keys.g.dart';

import '../controllers/chat_controller.dart';

class ChatView extends GetView<ChatController> {
  ChatView({super.key});

  final TextEditingController _questionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(LocaleKeys.chat)),
        centerTitle: true,
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: '单个连接演示'),
                Tab(text: '多个连接演示'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // 单个连接演示
                  _buildSingleConnectionDemo(),
                  // 多个连接演示
                  _buildMultipleConnectionDemo(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 单个连接演示 UI
  Widget _buildSingleConnectionDemo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 输入框
          TextField(
            controller: _questionController,
            decoration: const InputDecoration(
              labelText: '输入问题',
              hintText: '请输入您的问题...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          // 按钮区域
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => ElevatedButton(
                    onPressed: controller.isSSEConnected.value
                        ? null
                        : () {
                            final question = _questionController.text.trim();
                            if (question.isEmpty) {
                              Get.snackbar(
                                '提示',
                                '请输入问题',
                                snackPosition: SnackPosition.BOTTOM,
                              );
                              return;
                            }
                            controller.connectSSE(question);
                          },
                    child: const Text('发送'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Obx(
                () => ElevatedButton(
                  onPressed: controller.isSSEConnected.value
                      ? () => controller.disconnectSSE()
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('断开'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 连接状态
          Obx(
            () => Row(
              children: [
                Icon(
                  controller.isSSEConnected.value
                      ? Icons.check_circle
                      : Icons.cancel,
                  color: controller.isSSEConnected.value
                      ? Colors.green
                      : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  controller.isSSEConnected.value ? '已连接' : '未连接',
                  style: TextStyle(
                    color: controller.isSSEConnected.value
                        ? Colors.green
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          // 消息显示区域
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Obx(() {
                if (controller.sseMessage.value.isEmpty) {
                  return const Center(
                    child: Text(
                      '消息将显示在这里...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return SingleChildScrollView(
                  child: Text(
                    controller.sseMessage.value,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  /// 多个连接演示 UI
  Widget _buildMultipleConnectionDemo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 说明文字
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '演示：同时建立3个连接，都调用 /ai/chat/stream 接口',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 按钮区域
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => ElevatedButton(
                    onPressed: controller.isMultipleSSEConnected.value
                        ? null
                        : () => controller.connectMultipleSSE(),
                    child: const Text('建立3个连接'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Obx(
                () => ElevatedButton(
                  onPressed: controller.isMultipleSSEConnected.value
                      ? () => controller.disconnectMultipleSSE()
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('断开所有'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 连接状态和数量
          Obx(
            () => Row(
              children: [
                Icon(
                  controller.isMultipleSSEConnected.value
                      ? Icons.check_circle
                      : Icons.cancel,
                  color: controller.isMultipleSSEConnected.value
                      ? Colors.green
                      : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  controller.isMultipleSSEConnected.value
                      ? '已连接 (${controller.connectionCount}个)'
                      : '未连接',
                  style: TextStyle(
                    color: controller.isMultipleSSEConnected.value
                        ? Colors.green
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          // 三个连接的消息显示区域
          Expanded(
            child: Row(
              children: [
                // 连接1
                Expanded(
                  child: _buildConnectionMessageBox(
                    title: '连接1\n(什么是八字？)',
                    message: controller.sseMessage1,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                // 连接2
                Expanded(
                  child: _buildConnectionMessageBox(
                    title: '连接2\n(八字如何看财运？)',
                    message: controller.sseMessage2,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                // 连接3
                Expanded(
                  child: _buildConnectionMessageBox(
                    title: '连接3\n(八字中的五行是什么？)',
                    message: controller.sseMessage3,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建单个连接的消息显示框
  Widget _buildConnectionMessageBox({
    required String title,
    required RxString message,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Obx(() {
              if (message.value.isEmpty) {
                return const Center(
                  child: Text(
                    '等待消息...',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                );
              }
              return SingleChildScrollView(
                child: Text(
                  message.value,
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
