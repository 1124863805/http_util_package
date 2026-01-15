import 'response.dart';

/// 文件下载响应
/// 用于表示文件下载的结果
class DownloadResponse<T> extends Response<T> {
  /// 是否下载成功
  @override
  final bool isSuccess;

  /// 错误消息（如果下载失败）
  @override
  final String? errorMessage;

  /// 下载的文件路径（如果成功）
  final String? filePath;

  /// 下载的总字节数
  final int? totalBytes;

  /// 下载的响应数据（通常为 null，因为下载的是文件）
  @override
  final T? data;

  DownloadResponse({
    required this.isSuccess,
    this.errorMessage,
    this.filePath,
    this.totalBytes,
    this.data,
  });

  /// 创建成功响应
  static DownloadResponse<String> success({
    required String filePath,
    int? totalBytes,
  }) {
    return DownloadResponse<String>(
      isSuccess: true,
      filePath: filePath,
      totalBytes: totalBytes,
      data: filePath, // 将文件路径作为 data
    );
  }

  /// 创建失败响应
  static DownloadResponse<T> failure<T>({
    required String errorMessage,
  }) {
    return DownloadResponse<T>(
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }

  @override
  void handleError() {
    // 下载失败时，可以在这里实现自定义错误处理
    // 默认实现为空，由 HttpConfig.onError 处理
  }
}
