import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/yunshi_controller.dart';
import '../../daily_yunshi/views/daily_yunshi_view.dart';
import '../../monthly_yunshi/views/monthly_yunshi_view.dart';

class YunshiView extends GetView<YunshiController> {
  const YunshiView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('运势'),
        centerTitle: true,
        bottom: TabBar(
          controller: controller.tabController,
          tabs: const [
            Tab(text: '日运'),
            Tab(text: '月运'),
          ],
        ),
      ),
      body: TabBarView(
        controller: controller.tabController,
        children: const [
          DailyYunshiView(),
          MonthlyYunshiView(),
        ],
      ),
    );
  }
}
