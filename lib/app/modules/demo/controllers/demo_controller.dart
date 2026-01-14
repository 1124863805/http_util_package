import 'dart:io';
import 'package:get/get.dart';
import '../../../utils/file_upload_util.dart';
import '../../../utils/image_picker_util.dart';

class DemoController extends GetxController {
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

  /// 从相册选择图片
  Future<void> pickImageFromGallery() async {
    final file = await ImagePickerUtil.pickImageFromGallery();
    if (file != null) {
      await _uploadImage(file);
    }
  }

  /// 从相机拍摄图片
  Future<void> pickImageFromCamera() async {
    final file = await ImagePickerUtil.pickImageFromCamera();
    if (file != null) {
      await _uploadImage(file);
    }
  }

  /// 上传图片
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
      Get.snackbar('成功', '图片上传成功', snackPosition: SnackPosition.BOTTOM);
    }
  }
}
