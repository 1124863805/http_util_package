import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../generated/locale_keys.g.dart';

import '../controllers/about_controller.dart';

class AboutView extends GetView<AboutController> {
  const AboutView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(LocaleKeys.about)),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          context.tr(LocaleKeys.about),
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
