import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../../routes/app_pages.dart';
import 'package:dio_http_util/http_util.dart';
import '../../../../app/utils/auth_util.dart';
import '../../../../app/utils/form_validator.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final codeController = TextEditingController();
  final countdown = 0.obs;
  Timer? _countdownTimer;

  @override
  void onClose() {
    emailController.dispose();
    codeController.dispose();
    _countdownTimer?.cancel();
    super.onClose();
  }

  /// 发送验证码
  Future<void> sendVerificationCode() async {
    if (!FormValidator.validateEmail(emailController.text)) return;

    // 使用链式调用，更简洁
    await http
        .send(
          method: hm.post,
          path: '/auth/verify/email',
          isLoading: true,
          data: {"email": emailController.text.trim()},
        )
        .onSuccess(_startCountdown);
  }

  /// 开始倒计时
  void _startCountdown() {
    countdown.value = 60;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown.value > 0) {
        countdown.value--;
      } else {
        timer.cancel();
      }
    });
  }

  /// 登录
  Future<void> login() async {
    if (!FormValidator.validateEmail(emailController.text) ||
        !FormValidator.validateCode(codeController.text)) {
      return;
    }

    final email = emailController.text.trim();
    final code = codeController.text.trim();

    final response = await http.send(
      method: hm.post,
      path: '/auth/login/email',
      data: {"email": email, "code": code},
      isLoading: true,
    );

    print('🔹 登录响应: ${response.data}');

    // 使用链式调用和 extractField，更简洁优雅
    // final accessToken = await http
    //     .send(
    //       method: hm.post,
    //       path: '/auth/login/email',
    //       data: {"email": email, "code": code},
    //       isLoading: true,
    //     )
    //     .extractField<String>('accessToken');

    // // 失败时已经自动提示了，这里只处理成功的情况
    // if (accessToken != null && accessToken.isNotEmpty) {
    //   await AuthUtil.saveLoginInfo(accessToken: accessToken, email: email);
    //   // 业务逻辑：登录成功跳转，不提示（或者可以在这里自定义提示）
    //   Get.offAllNamed(Routes.MAIN);
    // }
  }
}
