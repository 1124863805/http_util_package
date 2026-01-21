import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../generated/locale_keys.g.dart';

import '../controllers/pet_controller.dart';

class PetView extends GetView<PetController> {
  const PetView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(LocaleKeys.pet)),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          context.tr(LocaleKeys.pet),
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
