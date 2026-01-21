import 'package:get/get.dart';

import '../controllers/yunshi_controller.dart';
import '../../daily_yunshi/controllers/daily_yunshi_controller.dart';
import '../../monthly_yunshi/controllers/monthly_yunshi_controller.dart';

class YunshiBinding extends Bindings {
  @override
  void dependencies() {
    // 注册主 Controller
    Get.lazyPut<YunshiController>(() => YunshiController());

    // 立即注册子页面的 Controller，确保进入页面时都已加载
    // 使用 put 而不是 lazyPut，这样在进入 yunshi 页面时就会立即初始化
    Get.put<DailyYunshiController>(DailyYunshiController());
    Get.put<MonthlyYunshiController>(MonthlyYunshiController());
  }
}
