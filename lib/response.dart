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
  /// 内部已处理异常，用户不需要 try-catch
  ///
  /// 示例：
  /// ```dart
  /// final token = response.extract<String>(
  ///   (data) => (data as Map)['token'] as String?,
  /// );
  /// ```
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

  /// 从 Map 提取模型（类型安全，自动处理类型检查和异常）
  /// 适用于从 Map<String, dynamic> 转换为模型类
  ///
  /// 如果数据不是 Map 类型，自动返回 null
  /// 内部已处理异常，用户只需要提供 fromJson 函数
  ///
  /// 示例：
  /// ```dart
  /// final user = response.extractModel<User>(User.fromJson);
  /// final uploadResult = response.extractModel<FileUploadResult>(
  ///   FileUploadResult.fromConfigJson,
  /// );
  /// ```
  R? extractModel<R>(R? Function(Map<String, dynamic> json) fromJson) {
    return extract<R>((data) {
      // 自动类型检查：如果不是 Map，返回 null
      if (data is! Map<String, dynamic>) return null;
      // 调用 fromJson，异常已在 extract 内部处理
      return fromJson(data);
    });
  }

  /// 从 Map 中提取字段（最简单的方式）
  /// 适用于从 Map<String, dynamic> 中直接获取字段值
  ///
  /// 如果数据不是 Map 类型，自动返回 null
  /// 内部已处理类型转换和异常，用户只需要提供字段名
  ///
  /// 示例：
  /// ```dart
  /// final token = response.extractField<String>('token');
  /// final userId = response.extractField<int>('userId');
  /// ```
  R? extractField<R>(String key) {
    return extract<R>((data) {
      if (data is! Map<String, dynamic>) return null;
      final value = data[key];
      if (value is R) return value;
      if (value == null) return null;
      try {
        return value as R;
      } catch (e) {
        return null;
      }
    });
  }

  /// 从 Map 中提取列表字段并转换为模型列表
  /// 适用于从 Map<String, dynamic> 中提取 List 字段并转换为模型列表
  ///
  /// 如果数据不是 Map 类型或字段不是 List，自动返回空列表
  /// 内部已处理类型转换和异常，用户只需要提供字段名和 fromJson 函数
  ///
  /// 示例：
  /// ```dart
  /// final users = response.extractList<User>('users', User.fromJson);
  /// final items = response.extractList<Item>('data.items', Item.fromJson);
  /// ```
  List<R> extractList<R>(
    String key,
    R Function(Map<String, dynamic> json) fromJson,
  ) {
    return extract<List<R>>((data) {
          if (data is! Map<String, dynamic>) return [];
          final list = data[key];
          if (list is! List) return [];
          return list
              .whereType<Map<String, dynamic>>()
              .map((item) => fromJson(item))
              .toList();
        }) ??
        [];
  }

  /// 从 Map 中提取嵌套字段（支持路径，如 'user.name'）
  /// 适用于从 Map<String, dynamic> 中提取嵌套字段值
  ///
  /// 如果数据不是 Map 类型或路径不存在，自动返回 null
  /// 内部已处理类型转换和异常，用户只需要提供路径
  ///
  /// 示例：
  /// ```dart
  /// final userName = response.extractPath<String>('user.name');
  /// final userId = response.extractPath<int>('user.profile.id');
  /// ```
  R? extractPath<R>(String path) {
    return extract<R>((data) {
      if (data is! Map<String, dynamic>) return null;
      final keys = path.split('.');
      dynamic value = data;
      for (final key in keys) {
        if (value is Map<String, dynamic>) {
          value = value[key];
        } else {
          return null;
        }
      }
      if (value is R) return value;
      if (value == null) return null;
      try {
        return value as R;
      } catch (e) {
        return null;
      }
    });
  }

  /// 获取数据（类型安全）
  T? getData() => isSuccess ? data : null;
}

/// Future<Response<T>> 扩展方法
/// 支持链式调用，在 await 后自动提取数据或模型
extension FutureResponseExtension<T> on Future<Response<T>> {
  /// 等待响应完成后，自动提取模型
  /// 支持链式调用，无需中间变量
  ///
  /// 示例：
  /// ```dart
  /// final uploadResult = await http.send(...).extractModel<FileUploadResult>(
  ///   FileUploadResult.fromConfigJson,
  /// );
  /// ```
  Future<R?> extractModel<R>(
    R? Function(Map<String, dynamic> json) fromJson,
  ) async {
    final response = await this;
    return response.extractModel<R>(fromJson);
  }

  /// 等待响应完成后，自动提取数据
  /// 支持链式调用，无需中间变量
  ///
  /// 示例：
  /// ```dart
  /// final token = await http.send(...).extract<String>(
  ///   (data) => (data as Map)['token'] as String?,
  /// );
  /// ```
  Future<R?> extract<R>(R? Function(T? data) extractor) async {
    final response = await this;
    return response.extract<R>(extractor);
  }

  /// 等待响应完成后，自动提取字段
  /// 支持链式调用，最简单的方式
  ///
  /// 示例：
  /// ```dart
  /// final token = await http.send(...).extractField<String>('token');
  /// final userId = await http.send(...).extractField<int>('userId');
  /// ```
  Future<R?> extractField<R>(String key) async {
    final response = await this;
    return response.extractField<R>(key);
  }

  /// 等待响应完成后，自动提取列表
  /// 支持链式调用，适用于提取列表数据
  ///
  /// 示例：
  /// ```dart
  /// final users = await http.send(...).extractList<User>('users', User.fromJson);
  /// ```
  Future<List<R>> extractList<R>(
    String key,
    R Function(Map<String, dynamic> json) fromJson,
  ) async {
    final response = await this;
    return response.extractList<R>(key, fromJson);
  }

  /// 等待响应完成后，自动提取嵌套字段
  /// 支持链式调用，适用于提取嵌套路径的字段
  ///
  /// 示例：
  /// ```dart
  /// final userName = await http.send(...).extractPath<String>('user.name');
  /// ```
  Future<R?> extractPath<R>(String path) async {
    final response = await this;
    return response.extractPath<R>(path);
  }

  /// 等待响应完成后，成功时执行回调
  /// 支持链式调用，无需中间变量
  ///
  /// 示例：
  /// ```dart
  /// await http.send(...).onSuccess(() => print('请求成功'));
  /// ```
  Future<Response<T>> onSuccess(VoidCallback callback) async {
    final response = await this;
    return response.onSuccess(callback);
  }

  /// 等待响应完成后，失败时执行回调
  /// 支持链式调用，无需中间变量
  ///
  /// 示例：
  /// ```dart
  /// await http.send(...).onFailure((error) => print('错误: $error'));
  /// ```
  Future<Response<T>> onFailure(Function(String) callback) async {
    final response = await this;
    return response.onFailure(callback);
  }
}
