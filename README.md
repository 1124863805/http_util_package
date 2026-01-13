# Dio HTTP Util

一个基于 Dio 封装的 HTTP 请求工具类，支持配置化的请求头注入和统一的错误处理。

## 特性

- ✅ 基于 Dio 封装，功能强大
- ✅ 支持静态和动态请求头注入
- ✅ 统一的 API 响应封装
- ✅ 自动错误处理和提示
- ✅ 类型安全的 HTTP 方法常量
- ✅ 简洁的 API 设计

## 安装

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  dio_http_util:
    git:
      url: https://github.com/1124863805/http_util_package.git
      ref: main
```

或者发布到 pub.dev 后：

```yaml
dependencies:
  dio_http_util: ^1.0.0
```

然后运行：

```bash
flutter pub get
```

## 快速开始

### 1. 配置 HTTP 工具类

```dart
import 'package:dio_http_util/http_util.dart';

void main() {
  HttpUtil.configure(
    HttpConfig(
      baseUrl: 'https://api.example.com/v1',
      staticHeaders: {
        'App-Channel': 'ios',
        'app': 'myapp',
      },
      dynamicHeaderBuilder: () async {
        final headers = <String, String>{};
        
        // 添加语言头
        headers['Accept-Language'] = 'zh_CN';
        
        // 添加认证头
        final token = await getToken();
        if (token != null) {
          headers['Authorization'] = 'Bearer $token';
        }
        
        return headers;
      },
      onError: (title, message) {
        // 自定义错误提示
        print('$title: $message');
      },
      // 启用日志打印（可选）
      enableLogging: true,  // 是否启用日志
      logPrintBody: true,   // 是否打印请求/响应 body
    ),
  );
}
```

### 2. 发送请求

```dart
import 'package:dio_http_util/http_util.dart';

// 使用 send 方法（自动处理错误）
final response = await http.send(
  method: hm.post,
  path: '/auth/login',
  data: {'email': 'user@example.com'},
);

// 处理响应
response.onSuccess(() {
  print('登录成功');
}).onFailure((error) {
  print('登录失败: $error');
});

// 提取数据
final token = response.extract<String>(
  (data) => (data as Map)['token'] as String?,
);
```

### 3. 原始请求（获取 Dio Response）

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

### 4. 日志打印功能

启用日志打印后，会自动在控制台输出请求和响应信息：

```dart
HttpUtil.configure(
  HttpConfig(
    baseUrl: 'https://api.example.com',
    enableLogging: true,        // 启用日志
    logPrintBody: true,         // 打印 body（设为 false 则不打印 body，更简洁）
    logEnableColor: true,       // 启用颜色（默认 true）
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
  enableColor: true,         // 是否启用颜色（默认 true）
  logMode: LogMode.complete, // 日志模式（默认 complete）
  showRequestHint: true,     // 请求时显示简要提示（默认 true）
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
| `staticHeaders` | `Map<String, String>?` | 静态请求头 |
| `dynamicHeaderBuilder` | `Future<Map<String, String>> Function()?` | 动态请求头构建器 |
| `networkErrorKey` | `String?` | 网络错误消息键（用于国际化） |
| `tipTitleKey` | `String?` | 提示标题键（用于国际化） |
| `onError` | `void Function(String, String)?` | 错误提示回调 |
| `enableLogging` | `bool` | 是否启用日志打印（默认 false） |
| `logPrintBody` | `bool` | 是否打印请求/响应 body（默认 true） |
| `logEnableColor` | `bool` | 是否启用日志颜色（默认 true） |
| `logMode` | `LogMode` | 日志打印模式（默认 `LogMode.complete`） |
| `logShowRequestHint` | `bool` | 是否在请求时显示简要提示（仅在 complete 模式下有效，默认 true） |

### ApiResponse<T>

API 响应封装类。

#### 属性

- `code`: 响应代码（0 表示成功）
- `message`: 响应消息
- `data`: 响应数据
- `isSuccess`: 是否成功（code == 0）

#### 方法

- `handleError()`: 自动处理错误（失败时显示提示）
- `onSuccess(callback)`: 成功时执行回调
- `onFailure(callback)`: 失败时执行回调
- `extract<R>(extractor)`: 提取并转换数据
- `getData()`: 获取数据（类型安全）

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

## 文件结构

```
lib/http_util/
├── http_config.dart      # 配置类
├── http_method.dart      # HTTP 方法常量
├── api_response.dart     # API 响应封装
├── http_util_impl.dart   # HTTP 工具类实现
├── http_util.dart        # 导出文件
└── README.md            # 文档
```

## 发布到 pub.dev

1. 创建独立的 package 目录
2. 添加 `pubspec.yaml`
3. 配置依赖和导出
4. 运行 `dart pub publish --dry-run` 检查
5. 运行 `dart pub publish` 发布

## License

MIT License - see [LICENSE](LICENSE) file for details.

## 发布到 pub.dev

详细发布指南请参考 [PUBLISH_GUIDE.md](PUBLISH_GUIDE.md)。
