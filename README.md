# Dio HTTP Util

基于 Dio 封装的 HTTP 请求工具类，支持配置化的请求头注入和统一的错误处理。

[![pub package](https://img.shields.io/pub/v/dio_http_util.svg)](https://pub.dev/packages/dio_http_util)
[![GitHub](https://img.shields.io/github/stars/1124863805/http_util_package?style=social)](https://github.com/1124863805/http_util_package)

- 📦 [Pub.dev](https://pub.dev/packages/dio_http_util)
- 🐙 [GitHub](https://github.com/1124863805/http_util_package)

## 特性

- ✅ 完全灵活的响应解析 - 支持任意响应结构，零假设设计
- ✅ 用户自定义响应类 - 通过 `Response<T>` 抽象类完全控制响应结构
- ✅ 统一的便利方法（`onSuccess`, `onFailure`, `extract`, `getData`）
- ✅ 自动错误处理和提示
- ✅ 类型安全的 HTTP 方法常量
- ✅ 可配置的日志打印

## 安装

```yaml
dependencies:
  dio_http_util: ^1.0.2
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
);

// 处理响应（错误已自动处理并提示，直接提取数据即可）
final token = response.extract<String>(
  (data) => (data as Map)['token'] as String?,
);
if (token != null) saveToken(token);
```

**说明：**
- 如果响应失败（`isSuccess == false`），工具类会自动调用 `onError` 回调显示错误提示
- `extract` 方法内部已检查 `isSuccess`，失败时返回 `null`
- `onSuccess` 是可选的，仅用于让成功逻辑更清晰
```

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
- `getData()` - 获取数据（类型安全，失败时返回 null）

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

## 核心设计理念

- **零假设**：不假设任何响应结构
- **完全灵活**：用户定义自己的响应类和解析器
- **统一接口**：所有响应类继承 `Response<T>`，提供统一方法

## License

MIT License
