import 'package:get/get.dart';
import '../../../routes/app_pages.dart';

class HomeController extends GetxController {
  /// 跳转到运势页面
  void goToYunshi() {
    Get.toNamed(Routes.YUNSHI);
  }

  /// 跳转到生辰表单页面
  void goToBirthInfoForm() {
    Get.toNamed(Routes.BIRTH_INFO_FORM);
  }
}
