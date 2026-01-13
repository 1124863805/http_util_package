import 'package:get/get.dart';
import '../../../routes/app_pages.dart';

class MineController extends GetxController {
  /// 跳转到登录页面
  void goToLogin() {
    Get.toNamed(Routes.LOGIN);
  }

  /// 跳转到我的订单
  void goToMyOrders() {
    Get.toNamed(Routes.MY_ORDERS);
  }

  /// 跳转到我的档案
  void goToMyProfile() {
    Get.toNamed(Routes.MY_PROFILE);
  }

  /// 跳转到我的报告
  void goToMyReports() {
    Get.toNamed(Routes.MY_REPORTS);
  }

  /// 跳转到设置
  void goToSettings() {
    Get.toNamed(Routes.SETTINGS);
  }

  /// 跳转到会员
  void goToMembership() {
    Get.toNamed(Routes.MEMBERSHIP);
  }

  /// 跳转到关于我们
  void goToAbout() {
    Get.toNamed(Routes.ABOUT);
  }

  /// 跳转到问题反馈
  void goToFeedback() {
    Get.toNamed(Routes.FEEDBACK);
  }
}
