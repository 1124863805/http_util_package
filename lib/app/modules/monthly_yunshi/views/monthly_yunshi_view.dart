import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../generated/locale_keys.g.dart';

import '../controllers/monthly_yunshi_controller.dart';

class MonthlyYunshiView extends GetView<MonthlyYunshiController> {
  const MonthlyYunshiView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_month, size: 80, color: Colors.blue),
          const SizedBox(height: 24),
          Text(
            context.tr(LocaleKeys.monthly_yunshi),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr(LocaleKeys.month_yunshi),
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
