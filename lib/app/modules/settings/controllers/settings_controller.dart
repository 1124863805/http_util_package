import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../services/locale_service.dart';

class SettingsController extends GetxController {
  final localeService = Get.find<LocaleService>();

  /// 切换语言
  Future<void> changeLanguage(Locale locale) async {
    await localeService.changeLocale(locale);
    // 重新构建应用以应用新语言
    Get.updateLocale(locale);
  }

  /// 重置到设备语言环境
  Future<void> resetToDeviceLocale() async {
    await localeService.resetLocale();
    if (Get.context != null) {
      Get.updateLocale(Get.context!.locale);
    }
  }

  /// 清除保存的语言设置
  Future<void> clearSavedLocale() async {
    await localeService.deleteSaveLocale();
  }
}
