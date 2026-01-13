# Dio HTTP Util

一个基于 Dio 封装的 HTTP 请求工具类，支持配置化的请求头注入和统一的错误处理。

## 特性

- ✅ 基于 Dio 封装，功能强大
- ✅ 支持静态和动态请求头注入
- ✅ **完全灵活的响应解析** - 支持任意响应结构，零假设设计
- ✅ **用户自定义响应类** - 通过 `Response<T>` 抽象类完全控制响应结构
- ✅ 统一的便利方法（`onSuccess`, `onFailure`, `extract`, `getData`）
- ✅ 自动错误处理和提示
- ✅ 类型安全的 HTTP 方法常量
- ✅ 简洁的 API 设计

## 安装

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  dio_http_util: ^1.0.1
```

然后运行：

```bash
flutter pub get
```

## 快速开始

### 完整初始化示例

以下是一个完整的初始化示例，展示如何在 Flutter 应用中配置和使用 `dio_http_util`：

#### 步骤 1：创建 HTTP 适配器（推荐）

**注意：** 如果您的 API 使用标准结构 `{code: int, message: String, data: dynamic}`，可以直接使用默认的 `StandardResponseParser`，无需创建自定义解析器。

创建一个适配器类来集中管理 HTTP 配置：

```dart
// lib/utils/http_adapter.dart
import 'package:dio_http_util/http_util.dart' as http_util;
import 'response_parser.dart';

class HttpAdapter {
  /// 初始化 HTTP 工具类配置
  static void init() {
    http_util.HttpUtil.configure(
      http_util.HttpConfig(
        // 必需：API 基础 URL
        baseUrl: 'https://api.example.com/v1',
        
        // 可选：响应解析器（不传递则使用默认的 StandardResponseParser）
        // responseParser: StandardResponseParser(), // 如果需要自定义解析器，可以传递
        
        // 可选：静态请求头
        staticHeaders: {
          'App-Channel': 'ios',
          'app': 'myapp',
        },
        
        // 可选：动态请求头构建器
        dynamicHeaderBuilder: () async {
          final headers = <String, String>{};
          
          // 添加语言头
          headers['Accept-Language'] = 'zh_CN';
          
          // 添加认证头（从存储中获取 token）
          final token = await getTokenFromStorage();
          if (token != null) {
            headers['Authorization'] = 'Bearer $token';
          }
          
          return headers;
        },
        
        // 可选：网络错误消息键（用于国际化）
        networkErrorKey: 'network_error_retry',
        
        // 可选：错误提示回调
        onError: (String message) {
          // 显示错误提示（可以使用 GetX、BotToast 等）
          print('错误: $message');
          // 或者使用 Get.snackbar、BotToast.showText 等
        },
        
        // 可选：日志配置
        enableLogging: true,        // 是否启用日志
        logPrintBody: true,         // 是否打印请求/响应 body
        logMode: LogMode.complete,  // 日志模式（默认 complete）
        logShowRequestHint: true,   // 请求时显示简要提示
      ),
    );
  }
  
  // 示例：从存储中获取 token
  static Future<String?> getTokenFromStorage() async {
    // 实现您的 token 获取逻辑
    return null;
  }
}
```

#### 步骤 2：在 main.dart 中初始化

在应用启动时调用初始化方法：

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:dio_http_util/http_util.dart';
import 'utils/http_adapter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化 HTTP 工具类配置（必须在发送请求之前调用）
  HttpAdapter.init();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      home: HomePage(),
    );
  }
}
```

#### 步骤 3：使用 HTTP 工具类发送请求

### 自定义响应解析器（可选）

如果您的 API 响应结构不是标准的 `{code, message, data}`，可以创建自定义解析器：

```dart
// lib/utils/custom_response_parser.dart
import 'package:dio/dio.dart' as dio_package;
import 'package:dio_http_util/http_util.dart';

/// 自定义响应解析器
class CustomResponseParser implements ResponseParser {
  @override
  Response<T> parse<T>(dio_package.Response response) {
    if (response.data is! Map<String, dynamic>) {
      return ApiResponse<T>(
        code: -1,
        message: '响应格式错误',
        data: null,
      );
    }

    final data = response.data as Map<String, dynamic>;
    return ApiResponse<T>(
      code: (data['code'] as int?) ?? -1,
      message: (data['message'] as String?) ?? '',
      data: data['data'],
    );
  }
}

// 然后在 HttpConfig 中传递：
HttpConfig(
  baseUrl: 'https://api.example.com/v1',
  responseParser: CustomResponseParser(), // 自定义解析器
)
```

配置完成后，就可以在应用的任何地方使用 `http.send()` 发送请求：

```dart
// lib/pages/login_page.dart
import 'package:dio_http_util/http_util.dart';

class LoginController {
  Future<void> login(String email, String password) async {
    // 发送登录请求
    final response = await http.send(
      method: hm.post,
      path: '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );
    
    // 处理响应
    response.onSuccess(() {
      print('登录成功');
      // 提取 token
      final token = response.extract<String>(
        (data) => (data as Map)['token'] as String?,
      );
      if (token != null) {
        // 保存 token
        saveToken(token);
      }
    }).onFailure((error) {
      print('登录失败: $error');
    });
  }
}
```

### 分页场景

`dio_http_util` 完全支持分页场景。您可以通过自定义响应类来处理分页数据。

#### 方式 1：分页信息在 data 内部（推荐）

假设您的 API 响应结构为：
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "list": [...],
    "page": 1,
    "pageSize": 20,
    "total": 100,
    "hasMore": true
  }
}
```

**步骤 1：定义分页数据模型**

```dart
// lib/models/paged_data.dart
class PagedData<T> {
  final List<T> list;
  final int page;
  final int pageSize;
  final int total;
  final bool hasMore;

  PagedData({
    required this.list,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.hasMore,
  });

  factory PagedData.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    return PagedData<T>(
      list: (json['list'] as List<dynamic>?)
              ?.map((item) => fromJsonT(item))
              .toList() ??
          [],
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}
```

**步骤 2：使用默认 ApiResponse（data 为 PagedData）**

```dart
// 发送分页请求
final response = await http.send<PagedData<User>>(
  method: hm.get,
  path: '/users',
  queryParameters: {'page': 1, 'pageSize': 20},
);

response.onSuccess(() {
  // 提取分页数据
  final pagedData = response.extract<PagedData<User>>(
    (data) => PagedData<User>.fromJson(
      data as Map<String, dynamic>,
      (item) => User.fromJson(item as Map<String, dynamic>),
    ),
  );

  if (pagedData != null) {
    print('当前页: ${pagedData.page}');
    print('总数: ${pagedData.total}');
    print('是否有更多: ${pagedData.hasMore}');
    print('数据列表: ${pagedData.list}');
  }
});
```

#### 方式 2：混合场景（分页和非分页接口共存）

如果您的 API 中既有分页接口，也有非分页接口，**必须使用 `PathBasedResponseParser`** 来区分。

**场景说明：**
- 分页接口：响应结构为 `{code, message, data: List<T>, page, pageSize, total, hasMore}`
- 非分页接口：响应结构为 `{code, message, data: T}`

**步骤 1：定义分页响应类**

```dart
// lib/models/paged_response.dart
import 'package:dio_http_util/http_util.dart';

/// 分页响应类
/// 假设 API 响应结构为：{code: int, message: String, data: List<T>, page: int, pageSize: int, total: int, hasMore: bool}
/// 注意：T 是列表项的类型，不是列表本身
class PagedResponse<T> extends Response<List<T>> {
  final int code;
  final String message;
  final List<T>? _data;
  final int page;
  final int pageSize;
  final int total;
  final bool hasMore;
  final bool isSuccess;

  PagedResponse({
    required this.code,
    required this.message,
    List<T>? data,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.hasMore,
    bool? isSuccess,
  })  : _data = data,
        isSuccess = isSuccess ?? (code == 0);

  @override
  String? get errorMessage => isSuccess ? null : message;

  @override
  List<T>? get data => _data;

  // 便利方法：获取当前页
  int get currentPage => page;

  // 便利方法：获取总页数
  int get totalPages => (total / pageSize).ceil();

  // 便利方法：是否还有下一页
  bool get hasNextPage => hasMore;
}
```

**步骤 2：创建分页响应解析器**

```dart
// lib/utils/paged_response_parser.dart
import 'package:dio/dio.dart' as dio_package;
import 'package:dio_http_util/http_util.dart';
import '../models/paged_response.dart';

/// 分页响应解析器
/// 专门用于解析分页接口的响应
class PagedResponseParser implements ResponseParser {
  @override
  Response<T> parse<T>(dio_package.Response response) {
    if (response.data is! Map<String, dynamic>) {
      return ApiResponse<T>(
        code: -1,
        message: '响应格式错误',
        data: null,
      );
    }

    final data = response.data as Map<String, dynamic>;
    
    // 解析列表数据（T 是列表项的类型）
    final listData = data['data'] as List<dynamic>? ?? [];
    final list = listData.map((item) => item as T).toList();
    
    return PagedResponse<T>(
      code: (data['code'] as int?) ?? -1,
      message: (data['message'] as String?) ?? '',
      data: list,
      page: (data['page'] as int?) ?? 1,
      pageSize: (data['pageSize'] as int?) ?? 20,
      total: (data['total'] as int?) ?? 0,
      hasMore: (data['hasMore'] as bool?) ?? false,
    ) as Response<T>;
  }
}
```

**步骤 3：使用 PathBasedResponseParser 区分分页和非分页接口（必需）**

```dart
// 在 HttpConfig 中配置
HttpUtil.configure(
  HttpConfig(
    baseUrl: 'https://api.example.com/v1',
    responseParser: PathBasedResponseParser(
      matchers: [
        // 分页接口使用分页解析器
        // 注意：这些接口返回的是 List<T>，所以调用时 T 应该是列表项类型
        PathMatcher(
          pattern: RegExp(r'^/users|^/orders|^/products'),
          parser: PagedResponseParser(),
        ),
      ],
      // 其他接口使用标准解析器（返回单个对象）
      defaultParser: StandardResponseParser(),
    ),
  ),
);
```

**步骤 4：使用分页响应**

```dart
// 分页接口：T 是列表项类型（如 User）
final response = await http.send<User>(
  method: hm.get,
  path: '/users',
  queryParameters: {'page': 1, 'pageSize': 20},
);

response.onSuccess(() {
  // 类型检查：分页接口返回 PagedResponse
  if (response is PagedResponse<User>) {
    final pagedResponse = response as PagedResponse<User>;
    print('当前页: ${pagedResponse.currentPage}');
    print('总页数: ${pagedResponse.totalPages}');
    print('是否有下一页: ${pagedResponse.hasNextPage}');
    print('数据列表: ${pagedResponse.data}'); // List<User>?
  }
});

// 非分页接口：T 是单个对象类型
final userResponse = await http.send<User>(
  method: hm.get,
  path: '/user/123',
);

userResponse.onSuccess(() {
  // 非分页接口返回 ApiResponse
  final user = userResponse.extract<User>(
    (data) => User.fromJson(data as Map<String, dynamic>),
  );
  print('用户信息: $user'); // User?
});
```

**关键点总结：**

1. **类型区分**：
   - 分页接口：`http.send<User>()` 返回 `PagedResponse<User>`，`data` 是 `List<User>?`
   - 非分页接口：`http.send<User>()` 返回 `ApiResponse<User>`，`data` 是 `User?`

2. **必须使用 PathBasedResponseParser**：
   - 不能只使用 `PagedResponseParser`，否则所有接口都会尝试解析为分页响应
   - 必须通过路径匹配来区分哪些接口是分页的

3. **类型安全**：
   - 通过 `is PagedResponse` 检查来区分响应类型
   - 或者使用不同的泛型参数（如 `PagedResponse<User>` vs `ApiResponse<User>`）

### 自定义响应类（可选）

如果您的 API 响应结构不是标准的 `{code, message, data}`，可以创建自己的响应类：

```dart
// lib/models/my_response.dart
import 'package:dio_http_util/http_util.dart';

/// 自定义响应类
/// 假设 API 响应结构为：{success: bool, error: String?, result: T?}
class MyResponse<T> extends Response<T> {
  final bool success;
  final String? error;
  final T? result;
  
  MyResponse({required this.success, this.error, this.result});
  
  @override
  bool get isSuccess => success;
  
  @override
  String? get errorMessage => error;
  
  @override
  T? get data => result;
}

// 对应的解析器
class MyResponseParser implements ResponseParser {
  @override
  Response<T> parse<T>(dio_package.Response response) {
    final data = response.data as Map<String, dynamic>;
    return MyResponse<T>(
      success: data['success'] == true,
      error: data['error'] as String?,
      result: data['result'] as T?,
    );
  }
}
```

### 发送请求示例

配置完成后，您可以在应用的任何地方使用 `http.send()` 发送请求：

```dart
import 'package:dio_http_util/http_util.dart';

// 使用 send 方法（自动处理错误）
final response = await http.send(
  method: hm.post,
  path: '/auth/login',
  data: {'email': 'user@example.com', 'password': '123456'},
);

// 处理响应
response.onSuccess(() {
  print('登录成功');
  
  // 提取数据
  final token = response.extract<String>(
    (data) => (data as Map)['token'] as String?,
  );
  
  if (token != null) {
    // 保存 token 等业务逻辑
    saveToken(token);
  }
}).onFailure((error) {
  print('登录失败: $error');
  // 错误已经通过 onError 回调自动提示了
});
```

### 原始请求（获取 Dio Response）

如果需要获取原始的 Dio Response 对象：

```dart
// 使用 request 方法获取原始响应
final rawResponse = await http.request(
  method: hm.get,
  path: '/users',
  queryParameters: {'page': 1},
);

print(rawResponse.statusCode);
print(rawResponse.data);
```

### 5. 响应解析器详解

`dio_http_util` 使用响应解析器来处理不同的 API 响应结构。您需要实现 `ResponseParser` 接口来定义如何解析响应。

#### 标准结构解析器

如果您的 API 使用标准结构 `{code: int, message: String, data: dynamic}`：

```dart
class StandardResponseParser implements ResponseParser {
  @override
  ApiResponse<T> parse<T>(dio_package.Response response) {
    if (response.data is! Map<String, dynamic>) {
      return ApiResponse<T>(
        code: -1,
        message: '响应格式错误',
        data: null,
      );
    }

    final data = response.data as Map<String, dynamic>;
    return ApiResponse<T>(
      code: (data['code'] as int?) ?? -1,
      message: (data['message'] as String?) ?? '',
      data: data['data'],
    );
  }
}
```

#### 字段名不同的解析器

如果您的 API 使用不同的字段名：

```dart
class FieldMappingParser implements ResponseParser {
  @override
  ApiResponse<T> parse<T>(dio_package.Response response) {
    if (response.data is! Map<String, dynamic>) {
      return ApiResponse<T>(
        code: -1,
        message: '响应格式错误',
        data: null,
      );
    }

    final data = response.data as Map<String, dynamic>;
    return ApiResponse<T>(
      code: (data['status'] as int?) ?? -1,      // status 映射到 code
      message: (data['msg'] as String?) ?? '',    // msg 映射到 message
      data: data['result'],                       // result 映射到 data
      isSuccess: data['status'] == 200,           // 自定义成功判断
    );
  }
}
```

#### 嵌套结构解析器

如果您的 API 使用嵌套结构：

```dart
class NestedResponseParser implements ResponseParser {
  @override
  ApiResponse<T> parse<T>(dio_package.Response response) {
    if (response.data is! Map<String, dynamic>) {
      return ApiResponse<T>(
        code: -1,
        message: '响应格式错误',
        data: null,
      );
    }

    final data = response.data as Map<String, dynamic>;
    
    if (data['success'] == true) {
      return ApiResponse<T>(
        code: 0,
        message: 'success',
        data: data['payload'],
      );
    } else {
      final error = data['error'] as Map<String, dynamic>?;
      return ApiResponse<T>(
        code: error?['code'] as int? ?? -1,
        message: error?['message'] as String? ?? '未知错误',
        data: null,
      );
    }
  }
}
```

#### 多路径解析器

如果不同的 API 路径使用不同的响应结构，可以使用 `PathBasedResponseParser`：

```dart
HttpUtil.configure(
  HttpConfig(
    baseUrl: 'https://api.example.com',
    responseParser: PathBasedResponseParser(
      matchers: [
        // /api/v1/* 使用标准结构
        PathMatcher(
          pattern: RegExp(r'^/api/v1/.*'),
          parser: StandardResponseParser(),
        ),
        
        // /api/v2/* 使用字段映射
        PathMatcher(
          pattern: RegExp(r'^/api/v2/.*'),
          parser: FieldMappingParser(),
        ),
        
        // /graphql 使用 GraphQL 解析
        PathMatcher(
          pattern: RegExp(r'^/graphql'),
          parser: GraphQLResponseParser(),
        ),
      ],
      defaultParser: StandardResponseParser(), // 默认解析器
    ),
  ),
);
```

### 6. 日志打印功能

启用日志打印后，会自动在控制台输出请求和响应信息：

```dart
HttpUtil.configure(
  HttpConfig(
    baseUrl: 'https://api.example.com',
    enableLogging: true,        // 启用日志
    logPrintBody: true,         // 打印 body（设为 false 则不打印 body，更简洁）
    logMode: LogMode.complete,  // 日志模式（默认 complete，推荐）
    logShowRequestHint: true,   // 请求时显示简要提示（仅在 complete 模式下有效）
  ),
);
```

#### 日志模式说明

`dio_http_util` 提供三种日志模式，可根据需求选择：

##### 1. 完整链路模式（LogMode.complete）- 推荐 ⭐

**特点：**
- 请求和响应一起打印，形成完整链路
- 自动显示请求耗时
- 每个请求有唯一ID，并发场景友好
- 请求时可选择显示简要提示

**适用场景：** 开发调试、问题排查、性能分析

**日志输出示例：**
```
→ POST https://api.example.com/auth/login [a1b2c3]
┌─────────────────────────────────────────────────────────────
│ [请求链路 #a1b2c3] POST /auth/login (耗时: 234ms) ✅
│ ───────────────────────────────────────────────────────────
│ 📤 Request:
│    Method: POST
│    URL: https://api.example.com/auth/login
│    Headers:
│      Content-Type: application/json
│      Authorization: Bearer xxx
│    Body:
│      {"email": "test@example.com", "code": "123456"}
│ ───────────────────────────────────────────────────────────
│ 📥 Response:
│    Status: 200 OK
│    Body:
│      {"code": 0, "message": "success", "data": {...}}
└─────────────────────────────────────────────────────────────
```

##### 2. 实时模式（LogMode.realTime）

**特点：**
- 请求时立即打印，响应时立即打印
- 实时性好，适合长时间请求

**适用场景：** 需要实时查看请求发出的场景

**日志输出示例：**
```
┌─────────────────────────────────────────────────────────────
│ Request: POST https://api.example.com/auth/login
│ Headers: ...
│ Body: ...
└─────────────────────────────────────────────────────────────
┌─────────────────────────────────────────────────────────────
│ Response: 200 OK
│ Request: POST https://api.example.com/auth/login
│ Body: ...
└─────────────────────────────────────────────────────────────
```

##### 3. 简要模式（LogMode.brief）

**特点：**
- 只打印关键信息（方法、URL、状态码、耗时）
- 日志简洁，适合生产环境

**适用场景：** 生产环境、日志量大的场景

**日志输出示例：**
```
→ POST https://api.example.com/auth/login
← 200 https://api.example.com/auth/login (234ms)
```

#### 手动添加日志拦截器

```dart
import 'package:dio_http_util/http_util.dart';

// 获取 Dio 实例
final dio = HttpUtil.dio;

// 手动添加日志拦截器
dio.interceptors.add(LogInterceptor(
  printBody: true,           // 是否打印 body
  logMode: LogMode.complete,  // 日志模式（默认 complete）
  showRequestHint: true,      // 请求时显示简要提示（默认 true）
));
```

### 5. 使用配置好的 Dio 实例（继承当前配置）

```dart
import 'package:dio_http_util/http_util.dart';

// 获取配置好的 Dio 实例（已包含所有拦截器和 baseUrl 配置）
final dio = HttpUtil.dio;

// 直接使用 Dio 进行特殊操作
dio.interceptors.add(LogInterceptor()); // 添加日志拦截器

// 或者直接调用 Dio 的方法（会使用配置的 baseUrl）
final response = await dio.get('/custom/endpoint');
```

### 5. 创建独立的 Dio 实例（不依赖当前配置）

```dart
import 'package:dio_http_util/http_util.dart';

// 创建独立的 Dio 实例（不包含拦截器和 baseUrl）
final customDio = HttpUtil.createDio();

// 自定义配置
customDio.options.baseUrl = 'https://other-api.com';
customDio.interceptors.add(LogInterceptor());

// 使用独立的 Dio 实例
final response = await customDio.get('/endpoint');

// 或者创建时直接指定 baseUrl
final anotherDio = HttpUtil.createDio(
  baseUrl: 'https://api.example.com',
  connectTimeout: Duration(seconds: 60),
);
```

## API 文档

### HttpConfig

配置类，用于初始化 HTTP 工具类。

| 参数 | 类型 | 说明 |
|------|------|------|
| `baseUrl` | `String` | 基础 URL（必需） |
| `responseParser` | `ResponseParser?` | 响应解析器（可选），用于将 Dio Response 转换为用户定义的 Response。如果不提供，默认使用 `StandardResponseParser`（处理标准结构：{code: int, message: String, data: dynamic}） |
| `staticHeaders` | `Map<String, String>?` | 静态请求头 |
| `dynamicHeaderBuilder` | `Future<Map<String, String>> Function()?` | 动态请求头构建器 |
| `networkErrorKey` | `String?` | 网络错误消息键（用于国际化，可选） |
| `onError` | `void Function(String message)?` | 错误提示回调（message 可能是国际化键，需要在回调中自行翻译） |
| `enableLogging` | `bool` | 是否启用日志打印（默认 false） |
| `logPrintBody` | `bool` | 是否打印请求/响应 body（默认 true） |
| `logMode` | `LogMode` | 日志打印模式（默认 `LogMode.complete`） |
| `logShowRequestHint` | `bool` | 是否在请求时显示简要提示（仅在 complete 模式下有效，默认 true） |

### ResponseParser

响应解析器接口，用户必须实现此接口来定义如何解析 API 响应。

#### 方法

- `parse<T>(Response response)`: 解析响应，返回用户定义的 `Response<T>`

#### 实现示例

```dart
class MyResponseParser implements ResponseParser {
  @override
  Response<T> parse<T>(dio_package.Response response) {
    // 自定义解析逻辑
    final data = response.data as Map<String, dynamic>;
    return ApiResponse(
      code: data['code'] as int? ?? -1,
      message: data['message'] as String? ?? '',
      data: data['data'],
    );
  }
}
```

**注意：** 您可以使用包提供的 `ApiResponse`，也可以创建自己的响应类（继承 `Response<T>`）。

### PathBasedResponseParser

路径匹配解析器，根据请求路径选择不同的解析器。

#### 构造函数

- `PathBasedResponseParser({required List<PathMatcher> matchers, required ResponseParser defaultParser})`

#### 使用示例

```dart
PathBasedResponseParser(
  matchers: [
    PathMatcher(
      pattern: RegExp(r'^/api/v1/.*'),
      parser: V1Parser(),
    ),
  ],
  defaultParser: StandardParser(),
)
```

### Response<T>

响应抽象类，所有响应类必须继承此类。

#### 抽象属性（必须实现）

- `isSuccess`: 是否成功（bool）
- `errorMessage`: 错误消息（String?，失败时返回）
- `data`: 响应数据（T?，成功时返回）

#### 方法（有默认实现，可重写）

- `handleError()`: 处理错误（默认实现为空，可重写以显示错误提示）
- `onSuccess(callback)`: 成功时执行回调，返回自身支持链式调用
- `onFailure(callback)`: 失败时执行回调，返回自身支持链式调用
- `extract<R>(extractor)`: 提取并转换数据（类型安全）
- `getData()`: 获取数据（类型安全）

#### 使用示例

```dart
// 定义自己的响应类
class MyResponse<T> extends Response<T> {
  final bool success;
  final String? error;
  final T? payload;
  
  MyResponse({required this.success, this.error, this.payload});
  
  @override
  bool get isSuccess => success;
  
  @override
  String? get errorMessage => error;
  
  @override
  T? get data => payload;
  
  // 可选：重写 handleError 以自定义错误处理
  @override
  void handleError() {
    if (!isSuccess && errorMessage != null) {
      print('错误: $errorMessage');
    }
  }
}
```

### ApiResponse<T>

API 响应封装类的**示例实现**，展示如何继承 `Response<T>`。

**注意：** 这是一个可选实现示例，假设响应结构为 `{code: int, message: String, data: dynamic}`。如果您的 API 响应结构不同，请创建自己的响应类。

#### 属性

- `code`: 响应代码（0 表示成功）
- `message`: 响应消息
- `data`: 响应数据
- `isSuccess`: 是否成功（code == 0）

#### 方法

继承自 `Response<T>` 的所有方法，并重写了 `handleError()` 以支持错误提示回调。

### HTTP 方法常量

使用 `hm` 类提供的常量：

- `hm.get`
- `hm.post`
- `hm.put`
- `hm.delete`
- `hm.patch`

### Dio 实例访问

#### 方式 1: 获取配置好的 Dio 实例（继承当前配置）

```dart
import 'package:dio_http_util/http_util.dart';

// 获取 Dio 实例（使用前必须先调用 HttpUtil.configure()）
// 该实例已包含 baseUrl、拦截器和请求头配置
final dio = HttpUtil.dio;

// 直接使用 Dio 进行特殊操作
dio.interceptors.add(LogInterceptor()); // 添加日志拦截器

// 或者直接调用 Dio 的方法（会使用配置的 baseUrl）
final response = await dio.get('/custom/endpoint');
```

**注意：** 使用前必须先调用 `HttpUtil.configure()` 进行配置。

#### 方式 2: 创建独立的 Dio 实例（不依赖当前配置）

```dart
import 'package:dio_http_util/http_util.dart';

// 创建独立的 Dio 实例（不包含拦截器和 baseUrl）
final customDio = HttpUtil.createDio();

// 自定义配置
customDio.options.baseUrl = 'https://other-api.com';
customDio.interceptors.add(LogInterceptor());

// 使用独立的 Dio 实例
final response = await customDio.get('/endpoint');
```

这种方式适用于需要访问不同 API 或不需要默认拦截器的场景。

## 核心设计理念

### 完全灵活的响应结构

`dio_http_util` 采用**零假设设计**，不假设任何响应结构。您必须：

1. **定义自己的响应类**（继承 `Response<T>`）
2. **实现响应解析器**（实现 `ResponseParser` 接口）

这样设计的好处：
- ✅ **完全灵活**：支持任意响应结构
- ✅ **类型安全**：通过泛型保证类型安全
- ✅ **统一接口**：所有响应类都继承 `Response<T>`，提供统一的便利方法
- ✅ **零假设**：工具类不假设任何响应结构

### 为什么需要继承 Response<T>？

`Response<T>` 抽象类提供了统一的便利方法（`onSuccess`, `onFailure`, `extract`, `getData`），这些方法在您的响应类中自动可用，无需重复实现。

## 文件结构

```
lib/
├── http_config.dart              # 配置类
├── http_method.dart              # HTTP 方法常量
├── response.dart                 # Response 抽象类（核心接口）
├── api_response.dart             # ApiResponse 示例实现（可选）
├── response_parser.dart          # ResponseParser 接口
├── parsers/
│   └── standard_response_parser.dart  # StandardResponseParser 示例
├── simple_error_response.dart    # SimpleErrorResponse（内部使用）
├── http_util_impl.dart           # HTTP 工具类实现
├── log_interceptor.dart          # 日志拦截器
├── http_util.dart                # 导出文件
└── README.md                     # 文档
```

## License

MIT License - see [LICENSE](LICENSE) file for details.
