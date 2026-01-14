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

  /// 从 JSON Map 创建 FileUploadResult
  /// 用于从 API 响应中解析配置信息
  factory FileUploadResult.fromConfigJson(Map<String, dynamic> json) {
    return FileUploadResult(
      uploadUrl: json['uploadUrl'] as String,
      imageKey: json['key'] as String,
      contentType: json['contentType'] as String?,
    );
  }

  /// 复制并更新 imageUrl
  FileUploadResult copyWith({String? imageUrl}) {
    return FileUploadResult(
      uploadUrl: uploadUrl,
      imageKey: imageKey,
      contentType: contentType,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

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

  /// 上传文件完整流程：获取配置 → 上传 OSS → 获取 URL（非链式调用版本）
  ///
  /// 这是传统写法，用于对比链式调用的优势
  ///
  /// [file] 要上传的文件
  /// [ext] 文件扩展名（可选，不提供则自动推断）
  /// [type] 文件类型（可选，不提供则自动推断：1图像 2视频 3表格 4头像）
  /// [onProgress] 上传进度回调
  ///
  /// 返回 [FileUploadResult] 或 null（失败时工具类已自动提示）
  static Future<FileUploadResult?> uploadFileNonChain({
    required File file,
    String? ext,
    int? type,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      // 推断扩展名和类型
      final fileExt = ext ?? _inferExtension(file);
      final fileType = type ?? _inferType(fileExt);

      // 步骤1：获取 OSS 配置
      final configResponse = await http.send(
        method: hm.post,
        path: '/uploader/generate',
        data: {'ext': fileExt, 'type': fileType},
      );

      // 提取配置信息
      final uploadResult = configResponse.extractModel<FileUploadResult>(
        FileUploadResult.fromConfigJson,
      );

      if (uploadResult == null) return null;

      // 步骤2：上传到 OSS
      final uploadResponse = await http.uploadToUrlResponse(
        uploadUrl: uploadResult.uploadUrl + "23123",
        file: file,
        method: 'PUT',
        headers: uploadResult.contentType != null
            ? {'Content-Type': uploadResult.contentType!}
            : null,
        onProgress: onProgress,
      );

      // 检查上传是否成功
      if (!uploadResponse.isSuccess) return null;

      // 步骤3：获取图片 URL
      final urlResponse = await http.send(
        method: hm.post,
        path: '/uploader/get-image-url',
        data: {'image_key': uploadResult.imageKey},
      );

      // 提取图片 URL
      final imageUrl = urlResponse.extractField<String>('image_url');

      if (imageUrl == null) return null;

      // 步骤4：更新对象并返回
      return uploadResult.copyWith(imageUrl: imageUrl);
    } catch (e) {
      return null; // 错误已由工具类自动提示
    }
  }

  /// 上传文件完整流程：获取配置 → 上传 OSS → 获取 URL（链式调用版本）
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

      // 获取 OSS 配置 → 上传到 OSS → 获取图片 URL → 更新对象（完整链路，一套调用）
      return await http
          .send(
            method: hm.post,
            path: '/uploader/generate',
            isLoading: true,
            data: {'ext': fileExt, 'type': fileType},
          )
          .extractModel<FileUploadResult>(FileUploadResult.fromConfigJson)
          .thenWith(
            (uploadResult) => http.uploadToUrlResponse(
              uploadUrl: uploadResult.uploadUrl,
              file: file,
              method: 'PUT',
              headers: uploadResult.contentType != null
                  ? {'Content-Type': uploadResult.contentType!}
                  : null,
              onProgress: onProgress,
            ),
          )
          .thenWithUpdate<String>(
            (uploadResult, uploadResponse) => http.send(
              method: hm.post,
              path: '/uploader/get-image-url',
              data: {'image_key': uploadResult.imageKey},
            ),
            (response) => response.extractField<String>('image_url'),
            (uploadResult, imageUrl) =>
                uploadResult.copyWith(imageUrl: imageUrl),
          );
    } catch (e) {
      return null; // 错误已由工具类自动提示
    }
  }
}
