import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/birth_info_form_controller.dart';

class BirthInfoFormView extends GetView<BirthInfoFormController> {
  const BirthInfoFormView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.isEditMode ? '修改生辰' : '添加生辰'),
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
                decoration: const InputDecoration(
                  labelText: '名称',
                  hintText: '请输入名称',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
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
                  decoration: const InputDecoration(
                    labelText: '性别',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.people),
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
                decoration: const InputDecoration(
                  labelText: '生日',
                  hintText: '请选择生日',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () => controller.selectBirthDate(context),
              ),
              const SizedBox(height: 16),

              // 出生地
              TextField(
                controller: controller.birthPlaceController,
                decoration: const InputDecoration(
                  labelText: '出生地',
                  hintText: '请输入出生地',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
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
                    controller.isEditMode ? '保存修改' : '添加',
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
