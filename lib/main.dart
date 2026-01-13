import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization/easy_localization.dart';

import 'app/routes/app_pages.dart';
import 'app/theme/app_theme.dart';
import 'app/services/locale_service.dart';
import 'generated/codegen_loader.g.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 GetStorage
  await GetStorage.init();

  // 初始化 easy_localization（必须在 runApp 之前调用）
  await EasyLocalization.ensureInitialized();

  // 初始化 LocaleService
  Get.put(LocaleService(), permanent: true);

  // 检查隐私协议状态，决定初始路由
  final storage = GetStorage();
  final hasAgreed = storage.read<bool>('privacy_agreed') ?? false;
  final initialRoute = hasAgreed ? Routes.MAIN : Routes.PRIVACY;

  runApp(
    EasyLocalization(
      // 支持的语言环境
      supportedLocales: LocaleService.supportedLocales,
      // 翻译文件路径
      path: 'assets/translations',
      // 回退语言环境（当找不到翻译时使用）
      fallbackLocale: LocaleService.fallbackLocale,
      // 使用生成的资源加载器（编译时加载，性能更好）
      assetLoader: const CodegenLoader(),
      // 保存语言环境到设备存储
      saveLocale: true,
      // 使用回退翻译（如果当前语言环境找不到键，尝试使用回退语言环境）
      useFallbackTranslations: true,
      // 如果区域设置文件中没有翻译，则尝试使用备用区域设置文件
      useFallbackTranslationsForEmptyResources: true,
      child: Builder(
        builder: (context) => GetMaterialApp(
          title: "合十 App",
          initialRoute: initialRoute,
          getPages: AppPages.routes,
          builder: (context, child) {
            child = BotToastInit()(context, child);
            return child;
          },
          navigatorObservers: [BotToastNavigatorObserver()], // 注册路由观察者
          theme: AppTheme.theme, // 使用应用主题配置
          // easy_localization 配置
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
        ),
      ),
    ),
  );
}
