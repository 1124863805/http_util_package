import 'response.dart';

/// ApiResponse 实现示例
/// 这是一个可选的实现示例，展示如何继承 Response 抽象类
/// 用户可以根据自己的需求创建自己的响应类
///
/// 此实现假设响应结构为：{code: int, message: String, data: dynamic}
class ApiResponse<T> extends Response<T> {
  final int code;
  final String message;
  final dynamic _data;
  final bool isSuccess;

  /// 错误消息显示回调（由 HttpConfig 注入）
  static void Function(String message)? _onError;

  /// 设置错误消息显示回调
  static void setErrorHandler(
    void Function(String message)? handler,
  ) {
    _onError = handler;
  }

  /// 构造函数
  ApiResponse({
    required this.code,
    required this.message,
    dynamic data,
    bool? isSuccess,
  })  : _data = data,
        isSuccess = isSuccess ?? (code == 0);

  @override
  String? get errorMessage => isSuccess ? null : message;

  @override
  T? get data => _data as T?;

  /// 自动处理错误（失败时自动显示错误消息）
  @override
  void handleError() {
    if (!isSuccess && _onError != null) {
      _onError!(message);
    }
  }
}
