import 'package:get/get.dart';

import '../controllers/settings_controller.dart';
import '../../../services/locale_service.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    // 确保 LocaleService 已初始化
    Get.put(LocaleService(), permanent: true);
    Get.lazyPut<SettingsController>(() => SettingsController());
  }
}
