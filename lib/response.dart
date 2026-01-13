import 'package:flutter/material.dart';

/// 响应接口
/// 用户必须实现此接口来定义自己的响应结构
///
/// 工具类通过此接口提供统一的便利方法（如 onSuccess, onFailure, handleError）
/// 但响应类的具体结构完全由用户定义
///
/// 示例：
/// ```dart
/// class MyResponse<T> implements Response<T> {
///   final bool success;
///   final String? error;
///   final T? payload;
///
///   MyResponse({required this.success, this.error, this.payload});
///
///   @override
///   bool get isSuccess => success;
///
///   @override
///   String? get errorMessage => error;
///
///   @override
///   T? get data => payload;
/// }
/// ```
abstract class Response<T> {
  /// 是否成功
  bool get isSuccess;

  /// 错误消息（如果失败）
  String? get errorMessage;

  /// 数据（如果成功）
  T? get data;

  /// 处理错误（可选实现，工具类会调用此方法）
  /// 默认实现为空，用户可以在自己的响应类中重写
  void handleError() {}

  /// 成功时执行回调
  /// 返回自身，支持链式调用
  Response<T> onSuccess(VoidCallback callback) {
    if (isSuccess) callback();
    return this;
  }

  /// 失败时执行回调
  /// 返回自身，支持链式调用
  Response<T> onFailure(Function(String) callback) {
    if (!isSuccess && errorMessage != null) {
      callback(errorMessage!);
    }
    return this;
  }

  /// 提取数据（自动处理类型转换）
  /// 仅在成功时执行提取器
  R? extract<R>(R? Function(T? data) extractor) {
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
  T? getData() => isSuccess ? data : null;
}
