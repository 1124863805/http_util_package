import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../generated/locale_keys.g.dart';

import '../controllers/my_orders_controller.dart';

class MyOrdersView extends GetView<MyOrdersController> {
  const MyOrdersView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(LocaleKeys.my_orders)),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          context.tr(LocaleKeys.my_orders),
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
