/// HTTP 异常类
/// 统一封装 HTTP 错误信息
class HttpException implements Exception {
  final int? statusCode;
  final String message;
  final dynamic data;

  HttpException({
    this.statusCode,
    required this.message,
    this.data,
  });

  @override
  String toString() => message;
}
