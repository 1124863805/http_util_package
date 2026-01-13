import 'package:get/get.dart';

import '../controllers/daily_yunshi_controller.dart';

class DailyYunshiBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DailyYunshiController>(
      () => DailyYunshiController(),
    );
  }
}
