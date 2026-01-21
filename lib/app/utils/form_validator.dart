import 'package:get/get.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../generated/locale_keys.g.dart';

/// 表单验证工具类
/// 统一处理表单验证逻辑
class FormValidator {
  /// 验证邮箱
  static bool validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      _showError(LocaleKeys.please_input_email);
      return false;
    }
    return true;
  }

  /// 验证验证码
  static bool validateCode(String? code) {
    if (code == null || code.trim().isEmpty) {
      _showError(LocaleKeys.please_input_code);
      return false;
    }
    return true;
  }

  /// 显示错误消息
  static void _showError(String key) {
    final context = Get.context;
    if (context != null) {
      Get.snackbar(
        context.tr(LocaleKeys.tip),
        context.tr(key),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
