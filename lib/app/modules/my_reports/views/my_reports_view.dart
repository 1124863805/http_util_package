import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/my_reports_controller.dart';

class MyReportsView extends GetView<MyReportsController> {
  const MyReportsView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的报告'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          '我的报告',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
