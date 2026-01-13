import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/chat_controller.dart';

class ChatView extends GetView<ChatController> {
  const ChatView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('倾诉'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          '倾诉',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
