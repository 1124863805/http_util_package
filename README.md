# Dio HTTP Util

基于 Dio 封装的 HTTP 请求工具类，支持配置化的请求头注入和统一的错误处理。

[![pub package](https://img.shields.io/pub/v/dio_http_util.svg)](https://pub.dev/packages/dio_http_util)
[![GitHub](https://img.shields.io/github/stars/1124863805/http_util_package?style=social)](https://github.com/1124863805/http_util_package)

- 📦 [Pub.dev](https://pub.dev/packages/dio_http_util)
- 🐙 [GitHub](https://github.com/1124863805/http_util_package)
- 📖 [English Documentation](README_EN.md) | [中文文档](README.md)

## 特性

- ✅ 完全灵活的响应解析 - 支持任意响应结构，零假设设计
- ✅ 用户自定义响应类 - 通过 `Response<T>` 抽象类完全控制响应结构
- ✅ 统一的便利方法（`onSuccess`, `onFailure`, `extract`, `getData`）
- ✅ 自动错误处理和提示
- ✅ 类型安全的 HTTP 方法常量
- ✅ 可配置的日志打印
- ✅ 文件上传支持 - 单文件、多文件上传，支持进度回调
- ✅ OSS 直传支持 - 直接上传到对象存储（阿里云、腾讯云等），不经过后端服务器
- ✅ Server-Sent Events (SSE) 支持 - 实时事件流处理
- ✅ 数据提取增强 - 提供 `extractField`、`extractModel`、`extractList`、`extractPath` 等简化方法
- ✅ 链式调用支持 - Future 扩展方法，支持流畅的链式调用
- ✅ 自动加载提示 - 支持自动显示/隐藏加载提示，无需手动管理

## 安装

```yaml
dependencies:
  dio_http_util: ^1.2.1
```

## 快速开始

### 1. 初始化配置

```dart
import 'package:dio_http_util/http_util.dart' as http_util;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化（responseParser 可选，默认使用 StandardResponseParser）
  http_util.HttpUtil.configure(
    http_util.HttpConfig(
      baseUrl: 'https://api.example.com/v1',
      staticHeaders: {'App-Channel': 'ios', 'app': 'myapp'},
      dynamicHeaderBuilder: () async {
        final headers = <String, String>{};
        headers['Accept-Language'] = 'zh_CN';
        final token = await getToken();
        if (token != null) headers['Authorization'] = 'Bearer $token';
        return headers;
      },
      onError: (message) => print('错误: $message'),
      enableLogging: true,
    ),
  );
  
  runApp(MyApp());
}
```

### 2. 发送请求

```dart
import 'package:dio_http_util/http_util.dart';

// 发送请求
final response = await http.send(
  method: hm.post,
  path: '/auth/login',
  data: {'email': 'user@example.com', 'code': '123456'},
  queryParameters: {'source': 'mobile'},  // 可选：查询参数
);

// 处理响应（错误已自动处理并提示，直接提取数据即可）

// 方式1：使用 extractField（最简单，推荐）
final token = response.extractField<String>('token');

// 方式2：使用 extract（通用方式，支持复杂逻辑）
final token2 = response.extract<String>(
  (data) => (data as Map)['token'] as String?,
);

// 方式3：链式调用（推荐，无需中间变量）
final token3 = await http.send(
  method: hm.post,
  path: '/auth/login',
  data: {'email': 'user@example.com', 'code': '123456'},
).extractField<String>('token');

if (token != null) saveToken(token);
```

**send 方法参数说明：**
- `method` - HTTP 方法（必需，使用 `hm.get`、`hm.post` 等常量）
- `path` - 请求路径（必需）
- `data` - 请求体数据（可选）
- `queryParameters` - URL 查询参数（可选）

**send 方法新增参数：**
- `isLoading` - 是否显示加载提示（默认 false），如果为 true 且配置了 `contextGetter`，将自动显示加载提示

**说明：**
- 如果响应失败（`isSuccess == false`），工具类会自动调用 `onError` 回调显示错误提示
- `extract` 方法内部已检查 `isSuccess`，失败时返回 `null`
- `onSuccess` 是可选的，仅用于让成功逻辑更清晰

## 数据提取方法

工具包提供了多种数据提取方法，让数据提取更简单：

### 1. extractField - 提取字段（最简单）

从 Map 中直接提取字段值，无需写 lambda 表达式：

```dart
// 同步使用
final token = response.extractField<String>('token');
final userId = response.extractField<int>('userId');

// 链式调用（推荐）
final token = await http.send(...).extractField<String>('token');
```

### 2. extractModel - 提取模型

从 Map 转换为模型类，自动处理类型检查：

```dart
// 定义模型
class User {
  final String name;
  final int age;
  User({required this.name, required this.age});
  factory User.fromJson(Map<String, dynamic> json) {
    return User(name: json['name'], age: json['age']);
  }
}

// 使用
final user = response.extractModel<User>(User.fromJson);

// 链式调用（推荐）
final user = await http.send(...).extractModel<User>(User.fromJson);
```

### 3. extractList - 提取列表

从 Map 中提取列表字段并转换为模型列表：

```dart
// 使用
final users = response.extractList<User>('users', User.fromJson);

// 链式调用（推荐）
final users = await http.send(...).extractList<User>('users', User.fromJson);
```

### 4. extractPath - 提取嵌套字段

支持路径提取，如 `user.name`：

```dart
// 使用
final userName = response.extractPath<String>('user.name');
final userId = response.extractPath<int>('user.profile.id');

// 链式调用（推荐）
final userName = await http.send(...).extractPath<String>('user.name');
```

### 5. extract - 通用提取（复杂场景）

支持复杂的数据提取逻辑：

```dart
final complex = response.extract<CustomType>(
  (data) => CustomType.fromComplexData(data),
);
```

## 加载提示功能

### 配置加载提示

在初始化时配置 `contextGetter` 和可选的 `loadingWidgetBuilder`：

```dart
HttpUtil.configure(
  HttpConfig(
    baseUrl: 'https://api.example.com/v1',
    // 配置 contextGetter（必需）
    contextGetter: () => Get.context, // 或 navigatorKey.currentContext
    // 可选：自定义加载提示 UI
    loadingWidgetBuilder: (context) => MyCustomLoadingWidget(),
  ),
);
```

### 使用加载提示

在请求时设置 `isLoading: true`：

```dart
// 自动显示/隐藏加载提示
final response = await http.send(
  method: hm.post,
  path: '/auth/login',
  data: {'email': 'user@example.com'},
  isLoading: true, // 自动显示加载提示
);
```

**注意：** 在链式调用中，只需在第一步设置 `isLoading: true`，整个链路会共享一个加载提示。详见 [链式调用中的加载提示管理](#链式调用中的加载提示管理)。

### 自定义加载提示 UI

```dart
HttpUtil.configure(
  HttpConfig(
    baseUrl: 'https://api.example.com/v1',
    contextGetter: () => Get.context,
    // 自定义加载提示 Widget
    loadingWidgetBuilder: (context) => Container(
      color: Colors.black54,
      child: Center(
        child: CircularProgressIndicator(),
      ),
    ),
  ),
);
```

## 链式调用

所有提取方法都支持链式调用，无需中间变量：

```dart
// 提取字段
final token = await http.send(...).extractField<String>('token');

// 提取模型
final user = await http.send(...).extractModel<User>(User.fromJson);

// 提取列表
final users = await http.send(...).extractList<User>('users', User.fromJson);

// 提取嵌套字段
final userName = await http.send(...).extractPath<String>('user.name');

// 成功/失败回调
await http.send(...)
  .onSuccess(() => print('成功'))
  .onFailure((error) => print('失败: $error'));

// 链式调用下一个请求（传递前一个响应）
final result = await http.send(...)
  .then((prevResponse) => http.send(
    method: hm.post,
    path: '/next-step',
    data: {'token': prevResponse.extractField<String>('token')},
  ));

// 条件链式调用
final result2 = await http.send(...)
  .thenIf(
    (prevResponse) => prevResponse.extractField<bool>('needNextStep') == true,
    (prevResponse) => http.send(method: hm.post, path: '/next-step'),
  );
```

### 链式调用中的加载提示管理

在链式调用中，如果第一步设置了 `isLoading: true`，整个链路只会显示**一个**加载提示，加载提示会在整个链路结束时（成功或失败）自动关闭。

**使用方式：**

```dart
// 第一步设置 isLoading: true，整个链路共享一个加载提示
final result = await http.send(
  method: hm.post,
  path: '/uploader/generate',
  data: {'ext': 'jpg'},
  isLoading: true, // 只在第一步设置，后续步骤自动继承
)
.extractModel<FileUploadResult>(FileUploadResult.fromConfigJson)
.thenWith(
  (uploadResult) => http.uploadToUrlResponse(
    uploadUrl: uploadResult.uploadUrl,
    file: file,
    method: 'PUT',
    // 不需要设置 isLoading，会自动复用第一步的加载提示
  ),
)
.thenWithUpdate<String>(
  (uploadResult, uploadResponse) => http.send(
    method: hm.post,
    path: '/uploader/get-image-url',
    data: {'image_key': uploadResult.imageKey},
    // 不需要设置 isLoading，会自动复用第一步的加载提示
  ),
  (response) => response.extractField<String>('image_url'),
  (uploadResult, imageUrl) => uploadResult.copyWith(imageUrl: imageUrl),
);
// 整个链路结束时，加载提示自动关闭
```

**优势：**
- ✅ 只需在第一步设置 `isLoading: true`
- ✅ 后续步骤自动继承，无需重复设置
- ✅ 整个链路只显示一个加载提示，避免闪烁
- ✅ 链路结束时自动关闭，无需手动管理

## 自定义响应解析器

### 简单自定义解析器

如果只是字段名不同：

```dart
import 'package:dio_http_util/http_util.dart';
import 'package:dio/dio.dart' as dio_package;

class CustomResponseParser implements ResponseParser {
  @override
  Response<T> parse<T>(dio_package.Response response) {
    final data = response.data as Map<String, dynamic>;
    return ApiResponse<T>(
      code: (data['code'] as int?) ?? -1,
      message: (data['message'] as String?) ?? '',
      data: data['data'],
    );
  }
}
```

### 智能解析器（处理不规范的响应结构）

如果后端响应结构不统一，可以实现智能解析器自动适配：

```dart
import 'package:dio_http_util/http_util.dart';
import 'package:dio/dio.dart' as dio_package;

class SmartResponseParser implements ResponseParser {
  @override
  Response<T> parse<T>(dio_package.Response response) {
    if (response.data is! Map<String, dynamic>) {
      return ApiResponse<T>(code: -1, message: '响应格式错误', data: null);
    }

    final data = response.data as Map<String, dynamic>;
    
    // 智能检测：尝试多种字段名
    int? code;
    String? message;
    dynamic dataValue;
    
    // 检测 code/status/errCode 等
    code = data['code'] as int? ?? 
           data['status'] as int? ?? 
           (data['errCode'] as int?);
    
    // 检测 message/msg/error 等
    message = data['message'] as String? ?? 
              data['msg'] as String? ?? 
              data['error'] as String? ?? 
              '';
    
    // 检测 data/result/payload 等
    dataValue = data['data'] ?? 
                data['result'] ?? 
                data['payload'];
    
    // 智能判断成功：code == 0 或 code == 200 或 status == 'success'
    bool isSuccess = false;
    if (code != null) {
      isSuccess = code == 0 || code == 200;
    } else if (data['success'] == true || data['status'] == 'success') {
      isSuccess = true;
    }
    
    return ApiResponse<T>(
      code: code ?? (isSuccess ? 0 : -1),
      message: message ?? '',
      data: dataValue,
      isSuccess: isSuccess,
    );
  }
}
```

### 智能分页解析器（处理不规范的分页结构）

如果后端分页结构不统一，可以自动检测并适配：

```dart
import 'package:dio_http_util/http_util.dart';
import 'package:dio/dio.dart' as dio_package;

class SmartPagedResponseParser implements ResponseParser {
  @override
  Response<T> parse<T>(dio_package.Response response) {
    if (response.data is! Map<String, dynamic>) {
      return ApiResponse<T>(code: -1, message: '响应格式错误', data: null);
    }

    final data = response.data as Map<String, dynamic>;
    
    // 检测是否有分页字段（多种可能的字段名）
    final hasPage = data.containsKey('page') || 
                    data.containsKey('pageNum') || 
                    data.containsKey('currentPage');
    final hasPageSize = data.containsKey('pageSize') || 
                        data.containsKey('page_size') || 
                        data.containsKey('limit');
    final hasTotal = data.containsKey('total') || 
                     data.containsKey('totalCount') || 
                     data.containsKey('count');
    
    // 如果检测到分页字段，解析为分页响应
    if (hasPage && hasPageSize) {
      // 获取分页信息（尝试多种字段名）
      final page = (data['page'] as int?) ?? 
                   (data['pageNum'] as int?) ?? 
                   (data['currentPage'] as int?) ?? 1;
      final pageSize = (data['pageSize'] as int?) ?? 
                       (data['page_size'] as int?) ?? 
                       (data['limit'] as int?) ?? 20;
      final total = (data['total'] as int?) ?? 
                    (data['totalCount'] as int?) ?? 
                    (data['count'] as int?) ?? 0;
      final hasMore = (data['hasMore'] as bool?) ?? 
                      (data['has_more'] as bool?) ?? 
                      (data['hasNext'] as bool?) ?? 
                      (page * pageSize < total);
      
      // 获取列表数据（尝试多种字段名）
      final listData = (data['data'] as List<dynamic>?) ?? 
                       (data['list'] as List<dynamic>?) ?? 
                       (data['items'] as List<dynamic>?) ?? 
                       (data['results'] as List<dynamic>?) ?? [];
      final list = listData.map((item) => item as T).toList();
      
      // 获取 code 和 message（尝试多种字段名）
      final code = (data['code'] as int?) ?? 
                   (data['status'] as int?) ?? 
                   (data['errCode'] as int?) ?? 0;
      final message = (data['message'] as String?) ?? 
                      (data['msg'] as String?) ?? 
                      (data['error'] as String?) ?? '';
      
      // 注意：这里需要用户自己实现 PagedResponse 类
      // 示例代码假设 PagedResponse 已定义（见下方"方式 2"示例）
      return ApiResponse<List<T>>(
        code: code,
        message: message,
        data: list,
      ) as Response<T>;
    }
    
    // 否则使用标准响应
    final code = (data['code'] as int?) ?? 
                 (data['status'] as int?) ?? 
                 (data['errCode'] as int?) ?? -1;
    final message = (data['message'] as String?) ?? 
                    (data['msg'] as String?) ?? 
                    (data['error'] as String?) ?? '';
    final dataValue = data['data'] ?? 
                      data['result'] ?? 
                      data['payload'];
    
    return ApiResponse<T>(
      code: code,
      message: message,
      data: dataValue,
    );
  }
}

// 使用智能解析器
HttpConfig(
  baseUrl: 'https://api.example.com/v1',
  responseParser: SmartPagedResponseParser(), // 自动适配各种不规范结构
)
```

**智能解析器的优势：**
- ✅ 自动适配多种字段名（`code`/`status`/`errCode`，`message`/`msg`/`error` 等）
- ✅ 自动检测分页结构（`page`/`pageNum`/`currentPage` 等）
- ✅ 自动适配分页字段位置（顶层或 data 内部）
- ✅ 处理不规范的响应结构，无需手动配置路径匹配

## 分页场景

### 方式 1：分页信息在 data 内部

```dart
// 定义分页数据模型
class PagedData<T> {
  final List<T> list;
  final int page;
  final int total;
  final bool hasMore;
  // ...
}

// 使用
final response = await http.send<PagedData<User>>(
  method: hm.get,
  path: '/users',
  queryParameters: {'page': 1, 'pageSize': 20},
);

final pagedData = response.extract<PagedData<User>>(
  (data) => PagedData<User>.fromJson(data as Map<String, dynamic>, ...),
);
```

### 方式 2：混合场景（分页和非分页接口共存）

```dart
import 'package:dio_http_util/http_util.dart';
import 'package:dio/dio.dart' as dio_package;

// 1. 定义分页响应类
class PagedResponse<T> extends Response<List<T>> {
  final int code;
  final String message;
  final List<T>? _data;
  final int page;
  final int pageSize;
  final int total;
  final bool hasMore;
  // ... 实现 Response 接口
}

// 2. 创建分页解析器
class PagedResponseParser implements ResponseParser {
  @override
  Response<T> parse<T>(dio_package.Response response) {
    final data = response.data as Map<String, dynamic>;
    final listData = data['data'] as List<dynamic>? ?? [];
    return PagedResponse<T>(
      code: (data['code'] as int?) ?? -1,
      message: (data['message'] as String?) ?? '',
      data: listData.map((item) => item as T).toList(),
      page: (data['page'] as int?) ?? 1,
      pageSize: (data['pageSize'] as int?) ?? 20,
      total: (data['total'] as int?) ?? 0,
      hasMore: (data['hasMore'] as bool?) ?? false,
    ) as Response<T>;
  }
}

// 3. 使用 PathBasedResponseParser 区分
HttpConfig(
  baseUrl: 'https://api.example.com/v1',
  responseParser: PathBasedResponseParser(
    matchers: [
      PathMatcher(
        pattern: RegExp(r'^/users|^/orders'),
        parser: PagedResponseParser(),
      ),
    ],
    defaultParser: StandardResponseParser(),
  ),
)

// 4. 使用
final response = await http.send<List<User>>(method: hm.get, path: '/users');
if (response is PagedResponse<User>) {
  final paged = response as PagedResponse<User>;
  print('列表: ${paged.data}, 总数: ${paged.total}');
}
```

## API 文档

### HttpConfig

| 参数 | 类型 | 说明 |
|------|------|------|
| `baseUrl` | `String` | 基础 URL（必需） |
| `responseParser` | `ResponseParser?` | 响应解析器（可选，默认 `StandardResponseParser`） |
| `staticHeaders` | `Map<String, String>?` | 静态请求头 |
| `dynamicHeaderBuilder` | `Future<Map<String, String>> Function()?` | 动态请求头构建器 |
| `networkErrorKey` | `String?` | 网络错误提示消息的键（用于国际化） |
| `onError` | `void Function(String message)?` | 错误提示回调 |
| `enableLogging` | `bool` | 是否启用日志（默认 false） |
| `logPrintBody` | `bool` | 是否打印 body（默认 true） |
| `logMode` | `LogMode` | 日志模式：`complete`（推荐）、`realTime`、`brief` |
| `logShowRequestHint` | `bool` | 是否在请求时显示简要提示（仅在 complete 模式下有效，默认 true） |
| `contextGetter` | `BuildContext? Function()?` | Context 获取器（用于加载提示功能） |
| `loadingWidgetBuilder` | `Widget Function(BuildContext)?` | 自定义加载提示 Widget 构建器（可选） |

### Response<T>

响应抽象类，所有响应类必须继承。

**必须实现的属性：**
- `bool get isSuccess` - 是否成功
- `String? get errorMessage` - 错误消息（如果失败）
- `T? get data` - 数据（如果成功）

**可选实现的方法：**
- `handleError()` - 处理错误（默认实现为空，用户可以在自己的响应类中重写）

**可用方法（有默认实现）：**
- `onSuccess(callback)` - 成功时执行回调
- `onFailure(callback)` - 失败时执行回调
- `extract<R>(extractor)` - 提取并转换数据（仅在成功时执行）
- `extractField<R>(key)` - 从 Map 提取字段（最简单的方式）
- `extractModel<R>(fromJson)` - 从 Map 提取模型（类型安全）
- `extractList<R>(key, fromJson)` - 从 Map 提取列表并转换为模型列表
- `extractPath<R>(path)` - 从 Map 提取嵌套字段（支持路径，如 'user.name'）
- `getData()` - 获取数据（类型安全，失败时返回 null）

**Future 扩展方法（支持链式调用）：**
- `Future<Response<T>>.extractField<R>(key)` - 链式调用提取字段
- `Future<Response<T>>.extractModel<R>(fromJson)` - 链式调用提取模型
- `Future<Response<T>>.extractList<R>(key, fromJson)` - 链式调用提取列表
- `Future<Response<T>>.extractPath<R>(path)` - 链式调用提取嵌套字段
- `Future<Response<T>>.extract<R>(extractor)` - 链式调用通用提取
- `Future<Response<T>>.onSuccess(callback)` - 链式调用成功回调
- `Future<Response<T>>.onFailure(callback)` - 链式调用失败回调
- `Future<Response<T>>.then<R>(nextRequest)` - 链式调用下一个请求（传递前一个响应）
- `Future<Response<T>>.thenIf<R>(condition, nextRequest)` - 条件链式调用

**提取后的对象链式调用扩展：**
- `Future<M?>.thenWith<R>(nextRequest)` - 传递提取的对象给下一个请求，返回 `ChainResult`
- `Future<M?>.thenWithExtract<R>(nextRequest, finalExtractor)` - 传递提取的对象并提取最终结果

**ChainResult 链式调用方法：**
- `ChainResult<M, R>.thenWith<R2>(nextRequest)` - 继续链式调用（中间步骤），返回 `ChainResult`
- `ChainResult<M, R>.thenWithUpdate<R2>(nextRequest, extractor, updater)` - 继续链式调用（最后一步），更新对象并返回
- `ChainResult<M, R>.thenWithExtract<R2>(nextRequest, finalExtractor)` - 继续链式调用并提取最终结果

**Future<ChainResult> 扩展方法：**
- `Future<ChainResult<M, R>>.thenWith<R2>(nextRequest)` - 继续链式调用（中间步骤）
- `Future<ChainResult<M, R>>.thenWithUpdate<R2>(nextRequest, extractor, updater)` - 继续链式调用（最后一步）

### ResponseParser

响应解析器接口，用户必须实现。

```dart
abstract class ResponseParser {
  Response<T> parse<T>(dio_package.Response response);
}
```

### PathBasedResponseParser

根据路径选择不同解析器。

```dart
PathBasedResponseParser(
  matchers: [
    PathMatcher(pattern: RegExp(r'^/api/v1/.*'), parser: V1Parser()),
  ],
  defaultParser: StandardResponseParser(),
)
```

### HTTP 方法常量

```dart
hm.get
hm.post
hm.put
hm.delete
hm.patch
```

### 获取 Dio 实例

```dart
// 获取配置好的实例
final dio = HttpUtil.dio;

// 创建独立实例（可选参数）
final customDio = HttpUtil.createDio(
  baseUrl: 'https://other-api.com',
  connectTimeout: Duration(seconds: 10),
  receiveTimeout: Duration(seconds: 10),
  sendTimeout: Duration(seconds: 10),
);
```

## 文件上传

### 单文件上传

**注意：** `uploadFile<T>` 中的泛型参数 `T` 表示**服务器响应的数据类型**，不是文件类型。根据你的 API 响应结构选择合适的类型。

**参数说明：**
- `path` - 请求路径（必需）
- `file` - 文件对象（File、String 路径或 Uint8List 字节数组，必需）
- `fieldName` - 表单字段名（默认 'file'）
- `fileName` - 文件名（可选，如果不提供则自动提取）
- `contentType` - Content-Type（可选，Dio 会根据文件名自动推断）
- `additionalData` - 额外的表单数据（除了文件之外的其他字段）
- `queryParameters` - URL 查询参数
- `onProgress` - 上传进度回调 `(sent, total) => void`
- `cancelToken` - 取消令牌，用于取消上传操作

**返回值：**
- 返回 `Future<Response<T>>`，其中 `T` 是服务器响应的数据类型
- 可以通过 `response.extract<T>()` 提取数据
- 可以通过 `response.isSuccess` 检查是否成功

```dart
import 'dart:io';
import 'package:dio_http_util/http_util.dart';

// 示例 1: 服务器返回文件 URL（String）
final response = await http.uploadFile<String>(
  path: '/api/upload',
  file: File('/path/to/image.jpg'),
  fieldName: 'avatar',
  additionalData: {'userId': '123'},
  queryParameters: {'category': 'avatar'},  // 查询参数
  onProgress: (sent, total) {
    print('上传进度: ${(sent / total * 100).toStringAsFixed(1)}%');
  },
  // cancelToken: cancelToken,  // 可选：用于取消上传
);
final fileUrl = response.extract<String>((data) => data as String?);

// 示例 2: 服务器返回 JSON 对象（Map）
final response2 = await http.uploadFile<Map<String, dynamic>>(
  path: '/api/upload',
  file: File('/path/to/image.jpg'),
  fieldName: 'avatar',
);
final result = response2.extract<Map<String, dynamic>>(
  (data) => data as Map<String, dynamic>?,
);
if (result != null) {
  print('文件 ID: ${result['id']}');
  print('文件 URL: ${result['url']}');
}

// 示例 3: 服务器返回自定义对象（需要定义模型类）
class UploadResult {
  final String id;
  final String url;
  UploadResult({required this.id, required this.url});
  factory UploadResult.fromJson(Map<String, dynamic> json) {
    return UploadResult(id: json['id'], url: json['url']);
  }
}

final response3 = await http.uploadFile<Map<String, dynamic>>(
  path: '/api/upload',
  file: '/path/to/image.jpg',
  fieldName: 'avatar',
);
final uploadResult = response3.extract<UploadResult>(
  (data) => UploadResult.fromJson(data as Map<String, dynamic>),
);

// 示例 4: 使用文件路径（String）或字节数组（Uint8List）
final response4 = await http.uploadFile<String>(
  path: '/api/upload',
  file: '/path/to/image.jpg',  // 文件路径
  fieldName: 'avatar',
);

final response5 = await http.uploadFile<String>(
  path: '/api/upload',
  file: imageBytes,  // 字节数组
  fieldName: 'avatar',
  fileName: 'image.jpg',
  contentType: 'image/jpeg',
);
```

### 多文件上传

**参数说明：**
- `path` - 请求路径（必需）
- `files` - 文件列表（必需，至少包含一个文件）
- `additionalData` - 额外的表单数据（除了文件之外的其他字段）
- `queryParameters` - URL 查询参数
- `onProgress` - 上传进度回调 `(sent, total) => void`
- `cancelToken` - 取消令牌，用于取消上传操作

**返回值：**
- 返回 `Future<Response<T>>`，其中 `T` 是服务器响应的数据类型
- 可以通过 `response.extract<T>()` 提取数据
- 可以通过 `response.isSuccess` 检查是否成功

**注意：** `files` 列表不能为空，否则会抛出 `ArgumentError`。

```dart
import 'dart:io';
import 'package:dio_http_util/http_util.dart';

final response = await http.uploadFiles<String>(
  path: '/api/upload/multiple',
  files: [
    UploadFile(
      file: File('/path/to/file1.jpg'),
      fieldName: 'images[]',
    ),
    UploadFile(
      file: File('/path/to/file2.jpg'),
      fieldName: 'images[]',
    ),
    UploadFile(
      filePath: '/path/to/file3.png',
      fieldName: 'images[]',
      fileName: 'custom_name.png',
      contentType: 'image/png',
    ),
  ],
  additionalData: {'albumId': '456', 'description': 'My photos'},
  queryParameters: {'albumType': 'photo'},  // 查询参数
  onProgress: (sent, total) {
    print('上传进度: ${(sent / total * 100).toStringAsFixed(1)}%');
  },
  // cancelToken: cancelToken,  // 可选：用于取消上传
);

// 处理响应
final url = response.extract<String>((data) => data as String?);
if (url != null) {
  print('上传成功，文件 URL: $url');
}
```

### UploadFile 参数说明

| 参数 | 类型 | 说明 |
|------|------|------|
| `file` | `File?` | 文件对象（优先使用） |
| `filePath` | `String?` | 文件路径（如果未提供 file） |
| `fileBytes` | `Uint8List?` | 文件字节数据（如果未提供 file 和 filePath） |
| `fieldName` | `String` | 表单字段名（必需，例如：'avatar', 'images[]'） |
| `fileName` | `String?` | 文件名（可选，如果不提供则自动提取） |
| `contentType` | `String?` | Content-Type（可选，如果不提供则自动推断） |

**注意：** `file`、`filePath` 和 `fileBytes` 必须提供其中一个。

### OSS 直传（前端直传到对象存储）

当后端返回预签名的上传 URL 时，可以直接上传到 OSS（阿里云、腾讯云等），不经过后端服务器。

**典型流程：**
1. 前端请求后端获取预签名上传 URL
2. 前端直接上传文件到 OSS
3. 上传成功后，OSS 返回成功响应

**示例（阿里云 OSS）：**

```dart
import 'dart:io';
import 'package:dio_http_util/http_util.dart';

// 1. 从后端获取预签名上传 URL
final uploadInfo = await http.send<Map<String, dynamic>>(
  method: hm.post,
  path: '/api/oss/upload-url',
  data: {
    'fileName': 'image.jpg',
    'contentType': 'image/jpeg',
  },
);

final uploadUrl = uploadInfo.extract<String>(
  (data) => (data as Map<String, dynamic>)['uploadUrl'] as String?,
);

if (uploadUrl != null) {
  // 2. 直接上传到 OSS（使用 PUT 方法，支持链式调用）
  final response = await http.uploadToUrlResponse(
    uploadUrl: uploadUrl,
    file: File('/path/to/image.jpg'),
    method: 'PUT',  // OSS 通常使用 PUT
    headers: {
      'Content-Type': 'image/jpeg',
      // 注意：OSS 签名头通常已经在 URL 中，不需要额外添加
    },
    onProgress: (sent, total) {
      print('上传进度: ${(sent / total * 100).toStringAsFixed(1)}%');
    },
  );

  // 3. 检查上传结果（自动处理错误提示）
  if (response.isSuccess) {
    print('上传成功');
    // 可以获取文件访问 URL
    final fileUrl = uploadInfo.extract<String>(
      (data) => (data as Map<String, dynamic>)['fileUrl'] as String?,
    );
  }
}
```

**示例（腾讯云 COS，使用 POST 表单上传）：**

```dart
final response = await http.uploadToUrlResponse(
  uploadUrl: uploadUrl,
  file: File('/path/to/image.jpg'),
  method: 'POST',
  headers: {
    'Content-Type': 'multipart/form-data',
  },
  onProgress: (sent, total) {
    print('上传进度: ${(sent / total * 100).toStringAsFixed(1)}%');
  },
);

if (response.isSuccess) {
  print('上传成功');
}
```

**示例（使用文件路径或字节数组）：**

```dart
// 使用文件路径
final response1 = await http.uploadToUrlResponse(
  uploadUrl: uploadUrl,
  file: '/path/to/image.jpg',
  method: 'PUT',
);

// 使用字节数组
final response2 = await http.uploadToUrlResponse(
  uploadUrl: uploadUrl,
  file: imageBytes,
  method: 'PUT',
  headers: {'Content-Type': 'image/jpeg'},
);
```

**uploadToUrlResponse 参数说明：**

| 参数 | 类型 | 说明 |
|------|------|------|
| `uploadUrl` | `String` | 完整的上传 URL（包含签名参数，必需） |
| `file` | `File/String/Uint8List` | 文件对象、路径或字节数组（必需） |
| `method` | `String` | HTTP 方法，默认为 'PUT'（OSS 通常使用 PUT） |
| `headers` | `Map<String, String>?` | 自定义请求头（OSS 签名头等） |
| `onProgress` | `Function(int, int)?` | 上传进度回调 `(sent, total) => void` |
| `cancelToken` | `CancelToken?` | 取消令牌，用于取消上传操作 |

**返回值：**
- 返回 `Future<Response<T>>`，支持链式调用
- 可以通过 `response.isSuccess` 检查是否成功
- 失败时会自动触发错误提示（通过 `HttpConfig.onError`）

**输入验证：**
- 自动验证 `uploadUrl` 是否为有效的 URL 格式，无效时抛出 `ArgumentError`
- 自动验证 `method` 是否为有效的 HTTP 方法（GET、POST、PUT、PATCH、DELETE），无效时抛出 `ArgumentError`
- 自动检查文件是否存在（File 或 String 路径），不存在时抛出 `FileSystemException`

**注意事项：**
- `uploadToUrlResponse` 不依赖 `baseUrl` 配置，直接使用完整 URL
- OSS 签名信息通常已经在 URL 中，一般不需要额外添加请求头
- 上传成功后，OSS 通常返回 200 或 204 状态码
- 上传失败时会自动触发错误提示（通过 `HttpConfig.onError`）
- 支持链式调用，可以继续使用 `.thenWith()` 等方法
- 如果需要获取文件访问 URL，通常需要从后端接口获取
- 进度回调中的 `sent` 和 `total` 可能为 -1（未知大小），需要在回调中处理

## Server-Sent Events (SSE)

### 基本使用（推荐 - 自动连接）

**重要：** `sse()` 方法返回的流在关闭时会**自动清理资源**，无需手动调用 `close()`。如果取消订阅，资源也会自动清理。**如果连接失败，资源也会自动清理。**

**参数说明：**
- `path` - 请求路径（必需）
- `queryParameters` - URL 查询参数（可选）

**返回值：**
- 返回 `Future<Stream<SSEEvent>>`，可以直接监听事件
- 如果连接失败，会抛出异常，但资源已自动清理

**异常处理：**
- 连接失败时会抛出异常（如 `StateError`、`HttpException` 等）
- 连接失败时资源会自动清理，无需手动处理

```dart
import 'package:dio_http_util/http_util.dart';

// 自动连接并获取事件流（推荐方式）
try {
  final stream = await http.sse(
    path: '/api/events',
    queryParameters: {'topic': 'notifications'},
  );
  
  // 监听事件
  final subscription = stream.listen(
    (event) {
      print('收到事件: ${event.data}');
    },
    onError: (error) {
      print('SSE 错误: $error');
    },
  );
} catch (e) {
  // 连接失败（资源已自动清理）
  print('SSE 连接失败: $e');
}

// 直接监听事件
final subscription = stream.listen(
  (event) {
    print('收到事件: ${event.data}');
    print('事件类型: ${event.event}');
    print('事件 ID: ${event.id}');
  },
  onError: (error) {
    print('SSE 错误: $error');
    // 可以在这里实现重连逻辑
  },
  onDone: () {
    print('SSE 连接关闭');
  },
);

// 取消订阅时会自动清理资源，无需手动调用 close()
// subscription.cancel();
```

### 手动控制连接（高级用法）

如果需要手动控制连接时机（例如延迟连接、重连等），可以使用 `sseClient()` 方法：

**参数说明：**
- `path` - 请求路径（必需）
- `queryParameters` - URL 查询参数（可选）

**返回值：**
- 返回 `SSEClient` 实例，需要手动调用 `connect()` 建立连接

```dart
import 'package:dio_http_util/http_util.dart';

// 创建客户端（不自动连接）
final client = http.sseClient(
  path: '/api/events',
  queryParameters: {'topic': 'notifications'},
);

// 稍后手动连接
try {
  await client.connect();
  
  // 监听事件
  client.events.listen(
    (event) {
      print('收到事件: ${event.data}');
    },
    onError: (error) {
      print('SSE 错误: $error');
      // 可以在这里实现重连逻辑
    },
    onDone: () {
      print('SSE 连接关闭');
    },
  );
} catch (e) {
  // 连接失败，需要手动清理资源
  await client.close();
  print('SSE 连接失败: $e');
}

// 关闭连接（在不需要时）
await client.close();
```

### 在 Flutter Widget 中使用

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio_http_util/http_util.dart';

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  StreamSubscription<SSEEvent>? _subscription;
  final List<String> _messages = [];

  @override
  void initState() {
    super.initState();
    _connectSSE();
  }

  Future<void> _connectSSE() async {
    try {
      // 使用自动连接方式（更简洁）
      // 注意：连接失败或取消订阅时会自动清理资源
      final stream = await http.sse(path: '/api/notifications');
      
      _subscription = stream.listen(
        (event) {
          setState(() {
            _messages.add(event.data);
          });
        },
        onError: (error) {
          print('SSE 错误: $error');
          // 可以在这里实现重连逻辑
        },
      );
    } catch (e) {
      // 连接失败（资源已自动清理）
      print('SSE 连接失败: $e');
      // 可以在这里实现重连逻辑
    }
  }

  @override
  void dispose() {
    // 取消订阅时会自动清理资源，无需手动调用 close()
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('通知')),
      body: ListView.builder(
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          return ListTile(title: Text(_messages[index]));
        },
      ),
    );
  }
}
```

### SSE 事件模型

```dart
class SSEEvent {
  /// 事件数据（必需）
  final String data;
  
  /// 事件类型（可选）
  final String? event;
  
  /// 事件 ID（可选，用于重连时指定最后接收的事件）
  final String? id;
  
  /// 重试间隔（毫秒，可选）
  final int? retry;
  
  SSEEvent({
    required this.data,
    this.event,
    this.id,
    this.retry,
  });
  
  @override
  String toString() {
    return 'SSEEvent(event: $event, id: $id, data: $data)';
  }
}
```

**字段说明：**
- `data` - 事件数据（必需），可能包含多行数据（用换行符分隔）
- `event` - 事件类型（可选），用于区分不同类型的事件
- `id` - 事件 ID（可选），用于重连时指定最后接收的事件
- `retry` - 重试间隔（毫秒，可选），服务器建议的重连间隔

### SSE 客户端 API

| 方法/属性 | 类型 | 说明 |
|----------|------|------|
| `connect()` | `Future<void>` | 建立 SSE 连接（如果已连接或正在连接中会抛出异常） |
| `events` | `Stream<SSEEvent>` | 事件流，用于监听服务器推送的事件 |
| `isClosed` | `bool` | 连接是否已关闭 |
| `isConnected` | `bool` | 连接是否已建立 |
| `close()` | `Future<void>` | 关闭连接并释放资源 |

**连接状态说明：**
- `isClosed == false && isConnected == false` - 未连接状态
- `isClosed == false && isConnected == true` - 已连接状态
- `isClosed == true` - 已关闭状态（无法再次使用）

**注意：**
- SSE 连接会自动使用配置的请求头（静态和动态）
- 连接建立后，服务器会持续推送事件
- 使用 `sse()` 方法时，流关闭会自动清理资源，无需手动调用 `close()`
- 使用 `sse()` 方法时，如果连接失败，资源也会自动清理
- 使用 `sseClient()` 方法时，记得在不需要时调用 `close()` 关闭连接以释放资源
- 使用 `sseClient()` 方法时，如果连接失败，需要手动调用 `close()` 清理资源
- 不能重复调用 `connect()`，如果已连接或正在连接中会抛出 `StateError`
- `connect()` 可能抛出的异常：
  - `StateError` - 如果客户端已关闭、已连接或正在连接中
  - `HttpException` - 如果 HTTP 响应状态码不是 200（连接失败时会自动清理资源）
  - `FormatException` - 如果 baseUrl 格式无效（在 `Uri.parse()` 时抛出）
  - 其他网络相关异常（如连接超时、DNS 解析失败等）
- 连接失败时，`_eventController` 会收到错误事件（如果尚未关闭）
- 连接失败时，所有已创建的资源（HttpClient、SSEStream 等）会自动清理

## 核心设计理念

- **零假设**：不假设任何响应结构
- **完全灵活**：用户定义自己的响应类和解析器
- **统一接口**：所有响应类继承 `Response<T>`，提供统一方法

## License

MIT License
