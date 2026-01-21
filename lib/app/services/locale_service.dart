import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:get/get.dart';

/// 多语言服务
/// 统一管理应用的语言切换
class LocaleService extends GetxService {
  /// 当前语言环境（响应式）
  /// 直接从 context.locale 获取，easy_localization 会自动管理
  Locale get currentLocale => Get.context?.locale ?? fallbackLocale;

  /// 支持的语言列表
  static const List<Locale> supportedLocales = [
    Locale('zh', 'CN'), // 简体中文
    Locale('zh', 'TW'), // 繁体中文
    Locale('en', 'US'), // 英文
    Locale('ja', 'JP'), // 日语
    Locale('ko', 'KR'), // 韩语
  ];

  /// 默认语言环境（回退语言）
  static const Locale fallbackLocale = Locale('zh', 'CN');

  /// 切换语言
  Future<void> changeLocale(Locale locale) async {
    if (Get.context != null) {
      await Get.context!.setLocale(locale);
    }
  }

  /// 重置到设备语言环境
  Future<void> resetLocale() async {
    if (Get.context != null) {
      await Get.context!.resetLocale();
    }
  }

  /// 获取设备语言环境
  Locale? get deviceLocale => Get.context?.deviceLocale;

  /// 删除保存的语言环境
  Future<void> deleteSaveLocale() async {
    if (Get.context != null) {
      await Get.context!.deleteSaveLocale();
    }
  }

  /// 获取语言显示名称
  String getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'zh':
        return locale.countryCode == 'TW' ? '繁體中文' : '简体中文';
      case 'en':
        return 'English';
      case 'ja':
        return '日本語';
      case 'ko':
        return '한국어';
      default:
        return locale.languageCode;
    }
  }
}
