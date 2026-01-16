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
      body: Padding(
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
      ),
    );
  }
}
