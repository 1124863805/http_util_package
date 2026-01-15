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

    // 使用链式调用和 extractField，更简洁优雅
    final tokenInfo = await http
        .send(
          method: hm.post,
          path: '/auth/login/email',
          data: {"email": email, "code": code},
          isLoading: true,
        )
        // .onFailure((httpStatusCode, errorCode, message) {
        //   // 打印错误信息，方便调试
        //   print(
        //     '🔍 [登录错误] HTTP 状态码: $httpStatusCode, 业务错误码: $errorCode, 错误消息: $message',
        //   );
        //   // 可以根据 httpStatusCode 和 errorCode 执行不同的业务逻辑
        //   // 例如：httpStatusCode == 401 表示 HTTP 未授权
        //   // 例如：errorCode == 1001 表示业务错误码 1001
        //   Get.snackbar('登录失败', message, snackPosition: SnackPosition.BOTTOM);
        // })
        .extractModel<TokenInfo>(TokenInfo.fromJson);

    // 失败时已经自动提示了，这里只处理成功的情况
    if (tokenInfo != null) {
      await AuthUtil.saveLoginInfo(
        accessToken: tokenInfo.accessToken!,
        email: email,
      );
      // 业务逻辑：登录成功跳转，不提示（或者可以在这里自定义提示）
      Get.offAllNamed(Routes.MAIN);
    }
  }
}
