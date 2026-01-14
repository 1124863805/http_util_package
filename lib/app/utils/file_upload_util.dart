import 'dart:io';
import 'package:dio_http_util/http_util.dart';

/// 文件上传结果模型
class FileUploadResult {
  /// OSS 上传 URL
  final String uploadUrl;

  /// 图片 Key（用于后续获取 URL）
  final String imageKey;

  /// 文件 Content-Type
  final String? contentType;

  /// 图片访问 URL（上传后获取）
  final String? imageUrl;

  FileUploadResult({
    required this.uploadUrl,
    required this.imageKey,
    this.contentType,
    this.imageUrl,
  });

  @override
  String toString() {
    return 'FileUploadResult(uploadUrl: $uploadUrl, imageKey: $imageKey, contentType: $contentType, imageUrl: $imageUrl)';
  }
}

/// 文件上传工具类
/// 封装完整的文件上传流程：获取配置 → 上传 OSS → 获取 URL
class FileUploadUtil {
  FileUploadUtil._();

  /// 文件类型枚举
  /// 1: 图像, 2: 视频, 3: 表格, 4: 头像
  static const int typeImage = 1;
  static const int typeVideo = 2;
  static const int typeDocument = 3;
  static const int typeAvatar = 4;

  /// 从文件路径推断扩展名
  static String _inferExtension(File file) {
    return file.path.split('.').last.toLowerCase();
  }

  /// 从扩展名推断文件类型（1:图像 2:视频 3:表格 4:头像，默认1）
  static int _inferType(String ext) {
    const imageExts = [
      'jpg',
      'jpeg',
      'png',
      'gif',
      'bmp',
      'webp',
      'svg',
      'ico',
    ];
    const videoExts = ['mp4', 'avi', 'mov', 'wmv', 'flv', 'mkv', 'webm', 'm4v'];
    const documentExts = [
      'xls',
      'xlsx',
      'csv',
      'pdf',
      'doc',
      'docx',
      'ppt',
      'pptx',
    ];

    final lowerExt = ext.toLowerCase();
    if (imageExts.contains(lowerExt)) return typeImage;
    if (videoExts.contains(lowerExt)) return typeVideo;
    if (documentExts.contains(lowerExt)) return typeDocument;
    return typeImage; // 默认图像
  }

  /// 上传文件完整流程：获取配置 → 上传 OSS → 获取 URL
  ///
  /// [file] 要上传的文件
  /// [ext] 文件扩展名（可选，不提供则自动推断）
  /// [type] 文件类型（可选，不提供则自动推断：1图像 2视频 3表格 4头像）
  /// [onProgress] 上传进度回调
  ///
  /// 返回 [FileUploadResult] 或 null（失败时工具类已自动提示）
  static Future<FileUploadResult?> uploadFile({
    required File file,
    String? ext,
    int? type,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      // 推断扩展名和类型
      final fileExt = ext ?? _inferExtension(file);
      final fileType = type ?? _inferType(fileExt);

      // 获取 OSS 配置
      final ossConfig = await http.send(
        method: hm.post,
        path: '/uploader/generate',
        data: {'ext': fileExt, 'type': fileType},
      );

      // 提取配置信息
      final uploadUrl = ossConfig.extract<String>(
        (data) => (data as Map<String, dynamic>)['uploadUrl'] as String?,
      );
      final imageKey = ossConfig.extract<String>(
        (data) => (data as Map<String, dynamic>)['key'] as String?,
      );
      final contentType = ossConfig.extract<String>(
        (data) => (data as Map<String, dynamic>)['contentType'] as String?,
      );

      if (uploadUrl == null || imageKey == null) return null;

      // 上传到 OSS
      final response = await http.uploadToUrl(
        uploadUrl: uploadUrl,
        file: file,
        method: 'PUT',
        headers: contentType != null ? {'Content-Type': contentType} : null,
        onProgress: onProgress,
      );

      if (response.statusCode != 200 && response.statusCode != 204) return null;

      // 获取图片 URL
      final urlResponse = await http.send(
        method: hm.post,
        path: '/uploader/get-image-url',
        data: {'image_key': imageKey},
      );

      final imageUrl = urlResponse.extract<String>(
        (data) => (data as Map<String, dynamic>)['image_url'] as String?,
      );

      return FileUploadResult(
        uploadUrl: uploadUrl,
        imageKey: imageKey,
        contentType: contentType,
        imageUrl: imageUrl,
      );
    } catch (e) {
      return null; // 错误已由工具类自动提示
    }
  }
}
