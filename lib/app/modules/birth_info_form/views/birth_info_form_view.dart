import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../generated/locale_keys.g.dart';

import '../controllers/birth_info_form_controller.dart';

class BirthInfoFormView extends GetView<BirthInfoFormController> {
  const BirthInfoFormView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.isEditMode
            ? context.tr(LocaleKeys.edit_birth_info)
            : context.tr(LocaleKeys.add_birth_info)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 名称
              TextField(
                controller: controller.nameController,
                decoration: InputDecoration(
                  labelText: context.tr(LocaleKeys.name),
                  hintText: context.tr(LocaleKeys.please_input_name),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),

              // 性别
              Obx(() {
                final currentGender = controller.selectedGender.value.isEmpty
                    ? null
                    : controller.selectedGender.value;
                return DropdownButtonFormField<String>(
                  initialValue: currentGender,
                  decoration: InputDecoration(
                    labelText: context.tr(LocaleKeys.gender),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.people),
                  ),
                  items: controller.genderOptions
                      .map((gender) => DropdownMenuItem(
                            value: gender,
                            child: Text(gender),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.selectGender(value);
                    }
                  },
                );
              }),
              const SizedBox(height: 16),

              // 生日
              TextField(
                controller: controller.birthDateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: context.tr(LocaleKeys.birthday),
                  hintText: context.tr(LocaleKeys.please_select_birthday),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.calendar_today),
                ),
                onTap: () => controller.selectBirthDate(context),
              ),
              const SizedBox(height: 16),

              // 出生地
              TextField(
                controller: controller.birthPlaceController,
                decoration: InputDecoration(
                  labelText: context.tr(LocaleKeys.birth_place),
                  hintText: context.tr(LocaleKeys.please_input_birth_place),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 32),

              // 提交按钮
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: controller.submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    controller.isEditMode
                        ? context.tr(LocaleKeys.save_changes)
                        : context.tr(LocaleKeys.add),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
