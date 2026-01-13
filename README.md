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
