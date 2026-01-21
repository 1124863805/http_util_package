import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';
import 'permission_util.dart';

/// 图片选择工具类
/// 封装图片选择逻辑，统一处理权限和选择流程
class ImagePickerUtil {
  ImagePickerUtil._();

  /// 从相册选择图片
  ///
  /// [context] BuildContext（可选，如果不提供则使用 Get.context）
  /// [maxAssets] 最大选择数量，默认为 1
  ///
  /// 返回选择的文件，如果用户取消或失败则返回 null
  static Future<File?> pickImageFromGallery({
    BuildContext? context,
    int maxAssets = 1,
  }) async {
    // 请求相册权限
    if (!await PermissionUtil.requestPhotoPermission()) {
      return null;
    }

    try {
      final result = await AssetPicker.pickAssets(
        context ?? Get.context!,
        pickerConfig: AssetPickerConfig(
          maxAssets: maxAssets,
          requestType: RequestType.image,
        ),
      );

      if (result == null || result.isEmpty) {
        return null;
      }

      final file = await result.first.file;
      return file;
    } catch (e) {
      Get.snackbar('错误', '选择图片失败: $e', snackPosition: SnackPosition.BOTTOM);
      return null;
    }
  }

  /// 从相机拍摄图片
  ///
  /// [context] BuildContext（可选，如果不提供则使用 Get.context）
  /// [enableAudio] 是否启用音频，默认为 false
  ///
  /// 返回拍摄的文件，如果用户取消或失败则返回 null
  static Future<File?> pickImageFromCamera({
    BuildContext? context,
    bool enableAudio = false,
  }) async {
    // 请求相机权限
    if (!await PermissionUtil.requestCameraPermission()) {
      return null;
    }

    try {
      final result = await CameraPicker.pickFromCamera(
        context ?? Get.context!,
        pickerConfig: CameraPickerConfig(enableAudio: enableAudio),
      );

      return result?.file;
    } catch (e) {
      Get.snackbar('错误', '拍摄图片失败: $e', snackPosition: SnackPosition.BOTTOM);
      return null;
    }
  }
}
