import 'package:dio/dio.dart' as dio_package;
import 'package:flutter/material.dart';

/// API 响应封装类
/// 统一封装后台返回的数据结构：{code: int, message: String, data: dynamic}
class ApiResponse<T> {
  final int code;
  final String message;
  final dynamic data;
  final bool isSuccess;

  /// 错误消息显示回调（由 HttpConfig 注入）
  static void Function(String message)? _onError;

  /// 设置错误消息显示回调
  static void setErrorHandler(
    void Function(String message)? handler,
  ) {
    _onError = handler;
  }

  ApiResponse({required this.code, required this.message, this.data})
      : isSuccess = code == 0;

  /// 从 Dio Response 创建 ApiResponse
  factory ApiResponse.fromResponse(dio_package.Response response) {
    // 类型安全检查
    if (response.data is! Map<String, dynamic>) {
      return ApiResponse<T>(code: -1, message: '响应格式错误', data: null);
    }
    final responseData = response.data as Map<String, dynamic>;
    return ApiResponse<T>(
      code: (responseData['code'] as int?) ?? -1,
      message: (responseData['message'] as String?) ?? '',
      data: responseData['data'],
    );
  }

  /// 自动处理错误（失败时自动显示错误消息）
  /// 返回是否成功，方便链式调用
  bool handleError() {
    if (!isSuccess && _onError != null) {
      _onError!(message);
    }
    return isSuccess;
  }

  /// 成功时执行回调（不自动提示，由业务逻辑决定）
  ApiResponse<T> onSuccess(VoidCallback callback) {
    if (isSuccess) callback();
    return this;
  }

  /// 失败时执行回调
  ApiResponse<T> onFailure(Function(String) callback) {
    if (!isSuccess) callback(message);
    return this;
  }

  /// 提取数据（自动处理类型转换）
  R? extract<R>(R? Function(dynamic data) extractor) {
    if (isSuccess && data != null) {
      try {
        return extractor(data);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// 获取数据（类型安全）
  T? getData() => isSuccess ? data as T? : null;
}
