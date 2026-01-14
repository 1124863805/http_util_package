import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../utils/file_upload_util.dart';

class ChatController extends GetxController {
  //TODO: Implement ChatController

  final count = 0.obs;
  final uploadedImageUrl = ''.obs; // 上传后的图片 URL
  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  void increment() => count.value++;

  /// 请求相机权限
  Future<bool> _requestCameraPermission() async {
    // 先检查当前权限状态
    var status = await Permission.camera.status;
    print('📱 相机权限当前状态: $status');

    // 如果已经授予，直接返回
    if (status.isGranted) {
      print('✅ 相机权限已授予');
      return true;
    }

    // 如果被永久拒绝，引导用户到设置
    if (status.isPermanentlyDenied) {
      print('❌ 相机权限被永久拒绝，需要到设置中开启');
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('权限提示'),
          content: const Text('相机权限被拒绝，请在设置中开启相机权限'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('去设置'),
            ),
          ],
        ),
      );

      if (result == true) {
        // 打开应用设置页面
        await openAppSettings();
      }
      return false;
    }

    // 如果被拒绝但未永久拒绝，尝试请求权限
    if (status.isDenied) {
      print('📱 请求相机权限...');
      status = await Permission.camera.request();
      print('📱 相机权限请求结果: $status');

      if (status.isGranted) {
        print('✅ 相机权限已授予');
        return true;
      } else if (status.isPermanentlyDenied) {
        print('❌ 相机权限被永久拒绝');
        final result = await Get.dialog<bool>(
          AlertDialog(
            title: const Text('权限提示'),
            content: const Text('相机权限被拒绝，请在设置中开启相机权限'),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                child: const Text('去设置'),
              ),
            ],
          ),
        );

        if (result == true) {
          await openAppSettings();
        }
        return false;
      } else {
        print('❌ 相机权限被拒绝: $status');
        Get.snackbar(
          '权限提示',
          '需要相机权限才能拍摄照片',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    }

    // 其他状态（如 restricted）
    print('❌ 相机权限状态异常: $status');
    return false;
  }

  /// 请求相册权限
  Future<bool> _requestPhotoPermission() async {
    // 先检查当前权限状态
    var status = await Permission.photos.status;
    print('📱 相册权限当前状态: $status');

    // 如果已经授予，直接返回
    if (status.isGranted) {
      print('✅ 相册权限已授予');
      return true;
    }

    // 如果被永久拒绝，引导用户到设置
    if (status.isPermanentlyDenied) {
      print('❌ 相册权限被永久拒绝，需要到设置中开启');
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('权限提示'),
          content: const Text('相册权限被拒绝，请在设置中开启相册权限'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('去设置'),
            ),
          ],
        ),
      );

      if (result == true) {
        // 打开应用设置页面
        await openAppSettings();
      }
      return false;
    }

    // 如果被拒绝但未永久拒绝，尝试请求权限
    if (status.isDenied) {
      print('📱 请求相册权限...');
      status = await Permission.photos.request();
      print('📱 相册权限请求结果: $status');

      if (status.isGranted) {
        print('✅ 相册权限已授予');
        return true;
      } else if (status.isPermanentlyDenied) {
        print('❌ 相册权限被永久拒绝');
        final result = await Get.dialog<bool>(
          AlertDialog(
            title: const Text('权限提示'),
            content: const Text('相册权限被拒绝，请在设置中开启相册权限'),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                child: const Text('去设置'),
              ),
            ],
          ),
        );

        if (result == true) {
          await openAppSettings();
        }
        return false;
      } else {
        print('❌ 相册权限被拒绝: $status');
        Get.snackbar(
          '权限提示',
          '需要相册权限才能选择图片',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    }

    // 其他状态（如 restricted）
    print('❌ 相册权限状态异常: $status');
    return false;
  }

  /// 从相册选择图片
  Future<void> pickImageFromGallery() async {
    if (!await _requestPhotoPermission()) return;

    try {
      final result = await AssetPicker.pickAssets(
        Get.context!,
        pickerConfig: const AssetPickerConfig(
          maxAssets: 1,
          requestType: RequestType.image,
        ),
      );

      final file = await result?.first.file;
      if (file != null) {
        await _uploadImage(file);
      }
    } catch (e) {
      Get.snackbar('错误', '选择图片失败: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// 从相机拍摄图片
  Future<void> pickImageFromCamera() async {
    if (!await _requestCameraPermission()) return;

    try {
      final result = await CameraPicker.pickFromCamera(
        Get.context!,
        pickerConfig: const CameraPickerConfig(enableAudio: false),
      );

      final file = await result?.file;
      if (file != null) {
        await _uploadImage(file);
      }
    } catch (e) {
      Get.snackbar('错误', '拍摄图片失败: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// 上传图片（链式调用版本）
  Future<void> _uploadImage(File file) async {
    final result = await FileUploadUtil.uploadFile(
      file: file,
      onProgress: (sent, total) {
        if (total > 0) {
          print('上传进度: ${(sent / total * 100).toStringAsFixed(1)}%');
        }
      },
    );

    if (result?.imageUrl != null) {
      uploadedImageUrl.value = result!.imageUrl!;
      Get.snackbar('成功', '图片上传成功（链式调用）', snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// 上传图片（非链式调用版本，用于对比）
  Future<void> _uploadImageNonChain(File file) async {
    final result = await FileUploadUtil.uploadFileNonChain(
      file: file,
      onProgress: (sent, total) {
        if (total > 0) {
          print('上传进度: ${(sent / total * 100).toStringAsFixed(1)}%');
        }
      },
    );

    if (result?.imageUrl != null) {
      uploadedImageUrl.value = result!.imageUrl!;
      Get.snackbar('成功', '图片上传成功（非链式调用）', snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// 从相册选择图片（非链式调用版本）
  Future<void> pickImageFromGalleryNonChain() async {
    if (!await _requestPhotoPermission()) return;

    try {
      final result = await AssetPicker.pickAssets(
        Get.context!,
        pickerConfig: const AssetPickerConfig(
          maxAssets: 1,
          requestType: RequestType.image,
        ),
      );

      final file = await result?.first.file;
      if (file != null) {
        await _uploadImageNonChain(file);
      }
    } catch (e) {
      Get.snackbar('错误', '选择图片失败: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// 从相机拍摄图片（非链式调用版本）
  Future<void> pickImageFromCameraNonChain() async {
    if (!await _requestCameraPermission()) return;

    try {
      final result = await CameraPicker.pickFromCamera(
        Get.context!,
        pickerConfig: const CameraPickerConfig(enableAudio: false),
      );

      final file = await result?.file;
      if (file != null) {
        await _uploadImageNonChain(file);
      }
    } catch (e) {
      Get.snackbar('错误', '拍摄图片失败: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }
}
