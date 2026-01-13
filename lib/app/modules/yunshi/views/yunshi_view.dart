import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../generated/locale_keys.g.dart';

import '../controllers/yunshi_controller.dart';
import '../../daily_yunshi/views/daily_yunshi_view.dart';
import '../../monthly_yunshi/views/monthly_yunshi_view.dart';

class YunshiView extends GetView<YunshiController> {
  const YunshiView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(LocaleKeys.yunshi)),
        centerTitle: true,
        bottom: TabBar(
          controller: controller.tabController,
          tabs: [
            Tab(text: context.tr(LocaleKeys.daily_yunshi)),
            Tab(text: context.tr(LocaleKeys.monthly_yunshi)),
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
