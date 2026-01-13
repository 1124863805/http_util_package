import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/daily_yunshi_controller.dart';

class DailyYunshiView extends GetView<DailyYunshiController> {
  const DailyYunshiView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wb_sunny, size: 80, color: Colors.orange),
          SizedBox(height: 24),
          Text(
            '日运',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            '今日运势内容',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
