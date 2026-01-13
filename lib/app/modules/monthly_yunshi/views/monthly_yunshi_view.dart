import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/monthly_yunshi_controller.dart';

class MonthlyYunshiView extends GetView<MonthlyYunshiController> {
  const MonthlyYunshiView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month, size: 80, color: Colors.blue),
          SizedBox(height: 24),
          Text(
            '月运',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text('本月运势内容', style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }
}
