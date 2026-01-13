import 'package:get/get.dart';

import '../controllers/monthly_yunshi_controller.dart';

class MonthlyYunshiBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MonthlyYunshiController>(
      () => MonthlyYunshiController(),
    );
  }
}
