import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/demo_controller.dart';

class DemoView extends GetView<DemoController> {
  const DemoView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('文件上传演示'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '文件上传测试',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                controller.pickImageFromGallery();
              },
              icon: const Icon(Icons.photo_library),
              label: const Text('从相册选择'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                controller.pickImageFromCamera();
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('拍照'),
            ),
            const SizedBox(height: 30),
            // 显示上传的图片
            Obx(() {
              if (controller.uploadedImageUrl.value.isEmpty) {
                return const SizedBox.shrink();
              }
              return Column(
                children: [
                  const Text(
                    '上传的图片',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        controller.uploadedImageUrl.value,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.error, color: Colors.red),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      controller.uploadedImageUrl.value,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
