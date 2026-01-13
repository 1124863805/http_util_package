import 'response.dart';

/// 简单的错误 Response 实现（内部使用）
/// 用于网络错误等场景的兜底实现
class SimpleErrorResponse<T> extends Response<T> {
  final String message;

  SimpleErrorResponse(this.message);

  @override
  bool get isSuccess => false;

  @override
  String? get errorMessage => message;

  @override
  T? get data => null;

  @override
  void handleError() {
    // 简单错误响应不需要额外处理
  }
}
