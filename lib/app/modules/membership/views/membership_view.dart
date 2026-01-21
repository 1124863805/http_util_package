import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../generated/locale_keys.g.dart';

import '../controllers/membership_controller.dart';

class MembershipView extends GetView<MembershipController> {
  const MembershipView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(LocaleKeys.membership)),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          context.tr(LocaleKeys.membership),
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
