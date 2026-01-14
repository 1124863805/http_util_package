import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

/// 权限请求工具类
/// 封装通用的权限请求逻辑，统一处理权限状态和用户引导
class PermissionUtil {
  PermissionUtil._();

  /// 请求权限
  ///
  /// [permission] 要请求的权限（如 Permission.camera、Permission.photos）
  /// [permissionName] 权限名称（用于提示用户，如 "相机权限"、"相册权限"）
  /// [deniedMessage] 权限被拒绝时的提示消息（可选，默认使用通用消息）
  ///
  /// 返回 true 表示权限已授予，false 表示权限未授予
  static Future<bool> requestPermission({
    required Permission permission,
    required String permissionName,
    String? deniedMessage,
  }) async {
    // 先检查当前权限状态
    var status = await permission.status;

    // 如果已经授予，直接返回
    if (status.isGranted) {
      return true;
    }

    // 如果被永久拒绝，引导用户到设置
    if (status.isPermanentlyDenied) {
      final result = await _showPermissionDialog(
        permissionName: permissionName,
        message: '$permissionName被拒绝，请在设置中开启$permissionName',
      );

      if (result == true) {
        await openAppSettings();
      }
      return false;
    }

    // 如果被拒绝但未永久拒绝，尝试请求权限
    if (status.isDenied) {
      status = await permission.request();

      if (status.isGranted) {
        return true;
      } else if (status.isPermanentlyDenied) {
        final result = await _showPermissionDialog(
          permissionName: permissionName,
          message: '$permissionName被拒绝，请在设置中开启$permissionName',
        );

        if (result == true) {
          await openAppSettings();
        }
        return false;
      } else {
        // 权限被拒绝，显示提示
        Get.snackbar(
          '权限提示',
          deniedMessage ?? '需要$permissionName才能使用此功能',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    }

    // 其他状态（如 restricted）
    return false;
  }

  /// 显示权限提示对话框
  static Future<bool?> _showPermissionDialog({
    required String permissionName,
    required String message,
  }) async {
    return await Get.dialog<bool>(
      AlertDialog(
        title: const Text('权限提示'),
        content: Text(message),
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
  }

  /// 请求相机权限
  static Future<bool> requestCameraPermission() {
    return requestPermission(
      permission: Permission.camera,
      permissionName: '相机权限',
      deniedMessage: '需要相机权限才能拍摄照片',
    );
  }

  /// 请求相册权限
  static Future<bool> requestPhotoPermission() {
    return requestPermission(
      permission: Permission.photos,
      permissionName: '相册权限',
      deniedMessage: '需要相册权限才能选择图片',
    );
  }
}
