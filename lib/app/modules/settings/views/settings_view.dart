import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_localization/easy_localization.dart';

import '../controllers/settings_controller.dart';
import '../../../services/locale_service.dart';
import '../../../../generated/locale_keys.g.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final localeService = Get.find<LocaleService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(LocaleKeys.settings)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 语言设置
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(LocaleKeys.language),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) {
                      final currentLocale = context.locale;
                      return Column(
                        children: LocaleService.supportedLocales.map((locale) {
                          final isSelected = currentLocale == locale;
                          return RadioListTile<Locale>(
                            title: Text(localeService.getLanguageName(locale)),
                            value: locale,
                            groupValue: currentLocale,
                            onChanged: (value) {
                              if (value != null) {
                                controller.changeLanguage(value);
                              }
                            },
                            selected: isSelected,
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
