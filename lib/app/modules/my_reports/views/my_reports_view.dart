import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../generated/locale_keys.g.dart';

import '../controllers/my_reports_controller.dart';

class MyReportsView extends GetView<MyReportsController> {
  const MyReportsView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(LocaleKeys.my_reports)),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          context.tr(LocaleKeys.my_reports),
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
