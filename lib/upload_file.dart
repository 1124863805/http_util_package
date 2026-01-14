import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart' as dio_package;

/// 上传文件信息
/// 用于封装文件上传所需的参数
class UploadFile {
  /// 文件对象（优先使用）
  final File? file;

  /// 文件路径（如果未提供 file，则使用此路径）
  final String? filePath;

  /// 文件字节数据（如果未提供 file 和 filePath，则使用此数据）
  final Uint8List? fileBytes;

  /// 表单字段名（例如：'avatar', 'images[]'）
  final String fieldName;

  /// 文件名（可选，如果不提供则从 file 或 filePath 中提取）
  final String? fileName;

  /// Content-Type（可选，如果不提供则根据文件扩展名自动推断）
  final String? contentType;

  UploadFile({
    this.file,
    this.filePath,
    this.fileBytes,
    required this.fieldName,
    this.fileName,
    this.contentType,
  }) : assert(
          file != null || filePath != null || fileBytes != null,
          '必须提供 file、filePath 或 fileBytes 之一',
        );

  /// 获取文件名
  String get name {
    if (fileName != null) return fileName!;
    if (file != null) return _extractFileName(file!.path);
    if (filePath != null) return _extractFileName(filePath!);
    return 'file';
  }

  /// 从文件路径中提取文件名（跨平台兼容）
  /// 支持 Windows (\) 和 Unix (/) 路径分隔符
  static String _extractFileName(String filePath) {
    // 处理 Windows 和 Unix 路径分隔符
    final lastSlash = filePath.lastIndexOf('/');
    final lastBackslash = filePath.lastIndexOf('\\');
    final lastSeparator = lastSlash > lastBackslash ? lastSlash : lastBackslash;
    
    if (lastSeparator >= 0 && lastSeparator < filePath.length - 1) {
      return filePath.substring(lastSeparator + 1);
    }
    return filePath;
  }

  /// 转换为 Dio 的 MultipartFile
  /// 注意：Dio 5.x 的 MultipartFile 不支持直接设置 contentType 参数
  /// Content-Type 会根据文件名自动推断，或由服务器处理
  Future<dio_package.MultipartFile> toMultipartFile() async {
    if (file != null) {
      return await dio_package.MultipartFile.fromFile(
        file!.path,
        filename: fileName ?? _extractFileName(file!.path),
      );
    } else if (filePath != null) {
      return await dio_package.MultipartFile.fromFile(
        filePath!,
        filename: fileName ?? _extractFileName(filePath!),
      );
    } else if (fileBytes != null) {
      return dio_package.MultipartFile.fromBytes(
        fileBytes!,
        filename: fileName ?? 'file',
      );
    } else {
      throw StateError('无法创建 MultipartFile：未提供文件数据');
    }
  }
}
