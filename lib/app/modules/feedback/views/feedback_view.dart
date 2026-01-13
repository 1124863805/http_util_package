import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/feedback_controller.dart';

class FeedbackView extends GetView<FeedbackController> {
  const FeedbackView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('问题反馈'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          '问题反馈',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
