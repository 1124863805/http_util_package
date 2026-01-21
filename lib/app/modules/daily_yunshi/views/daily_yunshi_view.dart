import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../generated/locale_keys.g.dart';

import '../controllers/daily_yunshi_controller.dart';

class DailyYunshiView extends GetView<DailyYunshiController> {
  const DailyYunshiView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wb_sunny, size: 80, color: Colors.orange),
          const SizedBox(height: 24),
          Text(
            context.tr(LocaleKeys.daily_yunshi),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr(LocaleKeys.today_yunshi),
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
