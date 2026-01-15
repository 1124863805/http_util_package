import 'package:flutter/material.dart';
import 'http_util_impl.dart' show HttpUtilSafeCall;

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
    final result = response.extractField<R>(key);
    // 如果这是单次请求（没有后续链式调用），且设置了 isLoading: true
    // 需要在提取完成后关闭 loading（因为 finally 块中 isChainCall = true 不会关闭）
    // 通过检查是否有链式调用的 loading 来判断
    // 如果 _chainLoadingId 存在且没有被后续链式调用使用，说明这是单次请求
    // 注意：这里使用微任务延迟检查，确保链式调用有机会设置状态
    if (HttpUtilSafeCall.hasChainLoading()) {
      // 延迟检查：如果是单次请求，会在微任务中关闭 loading
      Future.microtask(() {
        // 如果链式调用的 loading 仍然存在，说明没有后续链式调用（单次请求）
        // 需要关闭 loading
        if (HttpUtilSafeCall.hasChainLoading()) {
          HttpUtilSafeCall.closeChainLoading();
        }
      });
    }
    return result;
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
    final result = response.onSuccess(callback);
    // 如果这是单次请求（使用了 onSuccess 但没有后续链式调用），需要关闭 loading
    // 检查是否有 chain loading，如果有且这是最后一个操作，关闭它
    if (HttpUtilSafeCall.hasChainLoading()) {
      // 使用 Future.microtask 确保在回调执行后再关闭 loading
      Future.microtask(() {
        HttpUtilSafeCall.closeChainLoading();
      });
    }
    return result;
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
    final result = response.onFailure(callback);
    // 如果这是单次请求（使用了 onFailure 但没有后续链式调用），需要关闭 loading
    // 检查是否有 chain loading，如果有且这是最后一个操作，关闭它
    if (HttpUtilSafeCall.hasChainLoading()) {
      // 使用 Future.microtask 确保在回调执行后再关闭 loading
      Future.microtask(() {
        HttpUtilSafeCall.closeChainLoading();
      });
    }
    return result;
  }

  /// 链式调用下一个请求（支持传递前一个请求的 Response）
  /// 如果前一个请求失败，不会执行下一个请求
  ///
  /// 示例：
  /// ```dart
  /// final result = await http.send(...)
  ///   .then((prevResponse) => http.send(
  ///     method: hm.post,
  ///     path: '/next-step',
  ///     data: {'token': prevResponse.extractField<String>('token')},
  ///   ));
  /// ```
  Future<Response<R>> then<R>(
    Future<Response<R>> Function(Response<T> prevResponse) nextRequest,
  ) async {
    final prevResponse = await this;
    if (!prevResponse.isSuccess) {
      return prevResponse as Response<R>;
    }
    return await nextRequest(prevResponse);
  }

  /// 条件链式调用（根据前一个请求的结果决定是否执行下一个请求）
  ///
  /// 示例：
  /// ```dart
  /// final result = await http.send(...)
  ///   .thenIf(
  ///     (prevResponse) => prevResponse.extractField<bool>('needNextStep') == true,
  ///     (prevResponse) => http.send(method: hm.post, path: '/next-step'),
  ///   );
  /// ```
  Future<Response<R>> thenIf<R>(
    bool Function(Response<T> prevResponse) condition,
    Future<Response<R>> Function(Response<T> prevResponse) nextRequest,
  ) async {
    final prevResponse = await this;
    if (!prevResponse.isSuccess || !condition(prevResponse)) {
      return prevResponse as Response<R>;
    }
    return await nextRequest(prevResponse);
  }
}

/// 链式调用结果包装类
/// 用于在链路中同时传递提取的对象和响应
class ChainResult<M, R> {
  final M extracted;
  final Response<R> response;
  final bool _hasChainLoading;

  ChainResult({
    required this.extracted,
    required this.response,
    bool hasChainLoading = false,
  }) : _hasChainLoading = hasChainLoading;

  /// 继续链式调用，传递提取的对象和响应（中间步骤）
  ///
  /// 返回 ChainResult，可以继续链式调用
  /// 如果需要最后一步更新对象，请使用 `thenWithUpdate` 方法
  ///
  /// 示例：中间步骤，继续链式调用
  /// ```dart
  /// final chainResult = await http.send(...)
  ///   .extractModel<FileUploadResult>(FileUploadResult.fromConfigJson)
  ///   .thenWith((uploadResult) => http.uploadToUrlResponse(...));
  /// ```
  ///
  /// 注意：`thenWithUpdate` 是 `thenWith` + 提取 + 更新的便捷方法
  /// 由于 Dart 不支持根据参数改变返回类型，所以分为两个方法
  Future<ChainResult<M, R2>> thenWith<R2>(
    Future<Response<R2>> Function(M extracted, Response<R> prevResponse)
        nextRequest,
  ) async {
    if (!response.isSuccess) {
      // 前一步失败，触发错误提示并关闭加载提示
      response.handleError();
      if (_hasChainLoading) {
        HttpUtilSafeCall.closeChainLoading();
      }
      return ChainResult<M, R2>(
        extracted: extracted,
        response: response as Response<R2>,
        hasChainLoading: false,
      );
    }
    final nextResponse = await nextRequest(extracted, response);

    // 如果下一步失败，触发错误提示并关闭加载提示
    if (!nextResponse.isSuccess) {
      nextResponse.handleError();
      if (_hasChainLoading) {
        HttpUtilSafeCall.closeChainLoading();
      }
    }

    // 传递链式调用的加载状态
    return ChainResult<M, R2>(
      extracted: extracted,
      response: nextResponse,
      hasChainLoading: _hasChainLoading,
    );
  }

  /// 继续链式调用，传递提取的对象和响应，并提取最终结果
  ///
  /// **注意**：如果第一步设置了 `isLoading: true`，整个链路只显示一个加载提示
  /// 在链路结束时（成功或失败）自动关闭
  Future<R2?> thenWithExtract<R2>(
    Future<Response<dynamic>> Function(M extracted, Response<R> prevResponse)
        nextRequest,
    R2? Function(Response<dynamic> response) finalExtractor,
  ) async {
    if (!response.isSuccess) {
      // 前一步失败，关闭加载提示
      if (_hasChainLoading) {
        HttpUtilSafeCall.closeChainLoading();
      }
      return null;
    }
    final nextResponse = await nextRequest(extracted, response);
    if (!nextResponse.isSuccess) {
      // 下一步失败，关闭加载提示
      if (_hasChainLoading) {
        HttpUtilSafeCall.closeChainLoading();
      }
      return null;
    }
    // 链路成功完成，关闭加载提示
    if (_hasChainLoading) {
      HttpUtilSafeCall.closeChainLoading();
    }
    return finalExtractor(nextResponse);
  }

  /// 继续链式调用，传递提取的对象和响应，更新对象并返回（最后一步）
  ///
  /// **说明**：这是 `thenWith` + `extractor` + `updater` 的组合便捷方法
  /// 由于 Dart 不支持根据参数改变返回类型，所以分为两个方法：
  /// - `thenWith`：中间步骤，返回 `ChainResult` 继续链式调用
  /// - `thenWithUpdate`：最后一步，提取并更新对象，返回更新后的对象
  ///
  /// 示例：
  /// ```dart
  /// final result = await http.send(...)
  ///   .extractModel<FileUploadResult>(FileUploadResult.fromConfigJson)
  ///   .thenWith((uploadResult) => http.uploadToUrlResponse(...))
  ///   .thenWithUpdate<String>(
  ///     (uploadResult, uploadResponse) => http.send(...),
  ///     (response) => response.extractField<String>('image_url'),
  ///     (uploadResult, imageUrl) => uploadResult.copyWith(imageUrl: imageUrl),
  ///   );
  /// ```
  Future<M?> thenWithUpdate<R2>(
    Future<Response<dynamic>> Function(M extracted, Response<R> prevResponse)
        nextRequest,
    R2? Function(Response<dynamic> response) extractor,
    M Function(M extracted, R2? extractedValue) updater,
  ) async {
    if (!response.isSuccess) {
      // 前一步失败，触发错误提示并关闭加载提示
      response.handleError();
      if (_hasChainLoading) {
        HttpUtilSafeCall.closeChainLoading();
      }
      return null;
    }
    final nextResponse = await nextRequest(extracted, response);
    if (!nextResponse.isSuccess) {
      // 下一步失败，触发错误提示并关闭加载提示
      nextResponse.handleError();
      if (_hasChainLoading) {
        HttpUtilSafeCall.closeChainLoading();
      }
      return null;
    }
    // 链路成功完成，关闭加载提示
    if (_hasChainLoading) {
      HttpUtilSafeCall.closeChainLoading();
    }
    final extractedValue = extractor(nextResponse);
    return updater(extracted, extractedValue);
  }

  /// 获取提取的对象
  M get value => extracted;

  /// 获取响应
  Response<R> get responseValue => response;
}

/// 提取后的对象链式调用扩展
/// 支持在提取对象后继续链式调用，对象在链路中传递
extension ExtractedValueExtension<M> on Future<M?> {
  /// 链式调用：传递提取后的对象给下一个请求
  /// 返回 ChainResult，对象在链路中传递
  ///
  /// 示例：
  /// ```dart
  /// final result = await http.send(...)
  ///   .extractModel<FileUploadResult>(FileUploadResult.fromConfigJson)
  ///   .thenWith((uploadResult) => http.send(
  ///     method: hm.post,
  ///     path: '/get-url',
  ///     data: {'key': uploadResult.imageKey},
  ///   ));
  /// ```
  Future<ChainResult<M, R>> thenWith<R>(
    Future<Response<R>> Function(M extracted) nextRequest,
  ) async {
    final extracted = await this;
    if (extracted == null) {
      // 注意：这里无法创建 ChainResult，因为 extracted 为 null
      // 检查是否有链式调用的加载提示，如果有则关闭
      if (HttpUtilSafeCall.hasChainLoading()) {
        HttpUtilSafeCall.closeChainLoading();
      }
      throw StateError('提取的对象为 null，无法继续链式调用');
    }

    // 检查是否已有链式调用的加载提示（由第一步的 isLoading: true 创建）
    final hasChainLoading = HttpUtilSafeCall.hasChainLoading();

    final response = await nextRequest(extracted);
    return ChainResult<M, R>(
      extracted: extracted,
      response: response,
      hasChainLoading: hasChainLoading,
    );
  }

  /// 链式调用：传递提取后的对象给下一个请求，并提取最终结果
  /// 如果任何一步失败，返回 null
  ///
  /// 示例：
  /// ```dart
  /// final imageUrl = await http.send(...)
  ///   .extractModel<FileUploadResult>(FileUploadResult.fromConfigJson)
  ///   .thenWithExtract<String>(
  ///     (uploadResult) => http.send(
  ///       method: hm.post,
  ///       path: '/get-url',
  ///       data: {'key': uploadResult.imageKey},
  ///     ),
  ///     (response) => response.extractField<String>('image_url'),
  ///   );
  /// ```
  ///
  /// **注意**：如果第一步设置了 `isLoading: true`，整个链路只显示一个加载提示
  /// 在链路结束时（成功或失败）自动关闭
  Future<R?> thenWithExtract<R>(
    Future<Response<dynamic>> Function(M extracted) nextRequest,
    R? Function(Response<dynamic> response) finalExtractor,
  ) async {
    final extracted = await this;
    if (extracted == null) {
      // 检查是否有链式调用的加载提示，如果有则关闭
      if (HttpUtilSafeCall.hasChainLoading()) {
        HttpUtilSafeCall.closeChainLoading();
      }
      return null;
    }

    // 检查是否已有链式调用的加载提示
    final hasChainLoading = HttpUtilSafeCall.hasChainLoading();

    final nextResponse = await nextRequest(extracted);
    if (!nextResponse.isSuccess) {
      // 失败时关闭加载提示
      if (hasChainLoading) {
        HttpUtilSafeCall.closeChainLoading();
      }
      return null;
    }

    // 成功时关闭加载提示
    if (hasChainLoading) {
      HttpUtilSafeCall.closeChainLoading();
    }

    return finalExtractor(nextResponse);
  }
}

/// Future<ChainResult<M, R>> 扩展方法
/// 支持在 ChainResult 的 Future 上继续链式调用
extension FutureChainResultExtension<M, R> on Future<ChainResult<M, R>> {
  /// 继续链式调用（中间步骤）
  /// 等同于 await chainResult.thenWith(...)
  Future<ChainResult<M, R2>> thenWith<R2>(
    Future<Response<R2>> Function(M extracted, Response<R> prevResponse)
        nextRequest,
  ) async {
    final chainResult = await this;
    return await chainResult.thenWith<R2>(nextRequest);
  }

  /// 继续链式调用，传递提取的对象和响应，更新对象并返回（最后一步）
  /// 等同于 await chainResult.thenWithUpdate(...)
  ///
  /// 示例：
  /// ```dart
  /// final result = await http.send(...)
  ///   .extractModel<FileUploadResult>(FileUploadResult.fromConfigJson)
  ///   .thenWith((uploadResult) => http.uploadToUrlResponse(...))
  ///   .thenWithUpdate<String>(
  ///     (uploadResult, uploadResponse) => http.send(...),
  ///     (response) => response.extractField<String>('image_url'),
  ///     (uploadResult, imageUrl) => uploadResult.copyWith(imageUrl: imageUrl),
  ///   );
  /// ```
  Future<M?> thenWithUpdate<R2>(
    Future<Response<dynamic>> Function(M extracted, Response<R> prevResponse)
        nextRequest,
    R2? Function(Response<dynamic> response) extractor,
    M Function(M extracted, R2? extractedValue) updater,
  ) async {
    final chainResult = await this;
    return await chainResult.thenWithUpdate<R2>(
      nextRequest,
      extractor,
      updater,
    );
  }
}
