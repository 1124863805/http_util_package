import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../../routes/app_pages.dart';
import '../../../../app/utils/auth_util.dart';
import '../../../../app/utils/form_validator.dart';
import '../../../../app/utils/login_api.dart';

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

    final success = await LoginAPI.sendVerificationCode(
      email: emailController.text.trim(),
    );

    if (success) {
      _startCountdown();
    }
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

    // 使用登录 API 工具类
    final tokenInfo = await LoginAPI.loginByEmail(
      email: email,
      code: code,
      onFailure: (int? httpStatusCode, int? errorCode, String message) {
        print(
          '🔍 [登录错误] HTTP 状态码: $httpStatusCode, 业务错误码: $errorCode, 错误消息: $message',
        );
      },
    );

    // 失败时已经由全局 onFailure 处理了错误提示，这里只处理成功的情况
    if (tokenInfo == null) return;

    // 登录成功，保存登录信息并跳转
    await AuthUtil.saveLoginInfo(
      accessToken: tokenInfo.accessToken!,
      email: email,
    );
    Get.offAllNamed(Routes.MAIN);
  }
}
