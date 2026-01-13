import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';

class LoginController extends GetxController {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final isPasswordHidden = true.obs;

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  void login() {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      Get.snackbar(
        '提示',
        '请输入用户名和密码',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // TODO: 实现登录逻辑
    // 登录成功后跳转到主页面
    Get.offAllNamed(Routes.MAIN);
  }
}
