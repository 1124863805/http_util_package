import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BirthInfoFormController extends GetxController {
  // 表单字段
  final nameController = TextEditingController();
  final genderController = TextEditingController();
  final birthDateController = TextEditingController();
  final birthPlaceController = TextEditingController();

  // 性别选项
  final List<String> genderOptions = ['男', '女', '其他'];
  final selectedGender = ''.obs;
  DateTime? selectedBirthDate;

  // 是否编辑模式
  final bool isEditMode;

  BirthInfoFormController({this.isEditMode = false});

  @override
  void onInit() {
    super.onInit();
    // 如果是编辑模式，可以在这里加载已有数据
    if (isEditMode) {
      // TODO: 加载已有数据
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    genderController.dispose();
    birthDateController.dispose();
    birthPlaceController.dispose();
    super.onClose();
  }

  /// 选择性别
  void selectGender(String gender) {
    selectedGender.value = gender;
    genderController.text = gender;
  }

  /// 选择生日
  Future<void> selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedBirthDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('zh', 'CN'),
    );
    if (picked != null) {
      selectedBirthDate = picked;
      birthDateController.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  /// 提交表单
  void submitForm() {
    if (nameController.text.trim().isEmpty) {
      Get.snackbar('提示', '请输入名称', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (selectedGender.value.isEmpty) {
      Get.snackbar('提示', '请选择性别', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (selectedBirthDate == null) {
      Get.snackbar('提示', '请选择生日', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (birthPlaceController.text.trim().isEmpty) {
      Get.snackbar('提示', '请输入出生地', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // TODO: 保存数据
    final data = {
      'name': nameController.text.trim(),
      'gender': selectedGender.value,
      'birthDate': selectedBirthDate,
      'birthPlace': birthPlaceController.text.trim(),
    };

    Get.snackbar(
      '成功',
      isEditMode ? '修改成功' : '添加成功',
      snackPosition: SnackPosition.BOTTOM,
    );

    // 延迟返回
    Future.delayed(const Duration(milliseconds: 1500), () {
      Get.back(result: data);
    });
  }
}
