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
  final int? _httpStatusCode;

  /// 构造函数
  ApiResponse({
    required this.code,
    required this.message,
    dynamic data,
    bool? isSuccess,
    int? httpStatusCode,
  })  : _data = data,
        isSuccess = isSuccess ?? (code == 0),
        _httpStatusCode = httpStatusCode;

  @override
  String? get errorMessage => isSuccess ? null : message;

  @override
  int? get errorCode => isSuccess ? null : code;

  @override
  int? get httpStatusCode => _httpStatusCode;

  @override
  T? get data => _data as T?;

  /// 自动处理错误（失败时自动显示错误消息）
  /// 注意：错误处理现在统一由 HttpConfig.onFailure 处理
  @override
  void handleError() {
    // 错误处理已统一由 HttpConfig.onFailure 处理，此方法保留为空实现以保持接口兼容性
  }
}
