import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../../app/services/locale_service.dart';

class BirthInfoFormController extends GetxController {
  // 表单字段
  final nameController = TextEditingController();
  final genderController = TextEditingController();
  final birthDateController = TextEditingController();
  final birthPlaceController = TextEditingController();

  // 性别选项（使用 LocaleKeys）
  List<String> get genderOptions => [
        Get.context!.tr('male'),
        Get.context!.tr('female'),
        Get.context!.tr('other'),
      ];
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
    final localeService = Get.find<LocaleService>();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedBirthDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: localeService.currentLocale,
    );
    if (picked != null) {
      selectedBirthDate = picked;
      birthDateController.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  /// 提交表单
  void submitForm() {
    final context = Get.context!;
    if (nameController.text.trim().isEmpty) {
      Get.snackbar(
        context.tr(LocaleKeys.tip),
        context.tr(LocaleKeys.please_input_name),
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (selectedGender.value.isEmpty) {
      Get.snackbar(
        context.tr(LocaleKeys.tip),
        context.tr(LocaleKeys.please_select_gender),
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (selectedBirthDate == null) {
      Get.snackbar(
        context.tr(LocaleKeys.tip),
        context.tr(LocaleKeys.please_select_birthday),
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (birthPlaceController.text.trim().isEmpty) {
      Get.snackbar(
        context.tr(LocaleKeys.tip),
        context.tr(LocaleKeys.please_input_birth_place),
        snackPosition: SnackPosition.BOTTOM,
      );
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
      context.tr(LocaleKeys.success),
      isEditMode
          ? context.tr(LocaleKeys.edit_success)
          : context.tr(LocaleKeys.add_success),
      snackPosition: SnackPosition.BOTTOM,
    );

    // 延迟返回
    Future.delayed(const Duration(milliseconds: 1500), () {
      Get.back(result: data);
    });
  }
}
