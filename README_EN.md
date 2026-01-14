# Dio HTTP Util

A powerful HTTP utility package based on Dio with configurable header injection and unified error handling.

[![pub package](https://img.shields.io/pub/v/dio_http_util.svg)](https://pub.dev/packages/dio_http_util)
[![GitHub](https://img.shields.io/github/stars/1124863805/http_util_package?style=social)](https://github.com/1124863805/http_util_package)

- 📦 [Pub.dev](https://pub.dev/packages/dio_http_util)
- 🐙 [GitHub](https://github.com/1124863805/http_util_package)
- 📖 [English Documentation](README_EN.md) | [中文文档](README.md)

## Features

- ✅ Completely flexible response parsing - supports any response structure, zero assumptions design
- ✅ User-defined response classes - fully control response structure through `Response<T>` abstract class
- ✅ Unified convenience methods (`onSuccess`, `onFailure`, `extract`, `getData`)
- ✅ Automatic error handling and prompts
- ✅ Type-safe HTTP method constants
- ✅ Configurable logging
- ✅ File upload support - single file, multiple files upload, with progress callback
- ✅ OSS direct upload support - directly upload to object storage (Aliyun, Tencent Cloud, etc.), without going through backend server
- ✅ Server-Sent Events (SSE) support - real-time event stream processing
- ✅ Enhanced data extraction methods - simplified data extraction API
- ✅ Chain call support - Future extension methods for fluent chaining
- ✅ Automatic loading indicator - support automatic show/hide loading indicator

## Installation

```yaml
dependencies:
  dio_http_util: ^1.2.0
```

## Quick Start

### 1. Initialize Configuration

```dart
import 'package:dio_http_util/http_util.dart' as http_util;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize (responseParser is optional, defaults to StandardResponseParser)
  http_util.HttpUtil.configure(
    http_util.HttpConfig(
      baseUrl: 'https://api.example.com/v1',
      staticHeaders: {'App-Channel': 'ios', 'app': 'myapp'},
      dynamicHeaderBuilder: () async {
        final headers = <String, String>{};
        headers['Accept-Language'] = 'en_US';
        final token = await getToken();
        if (token != null) headers['Authorization'] = 'Bearer $token';
        return headers;
      },
      onError: (message) => print('Error: $message'),
      // Configure loading indicator (optional)
      contextGetter: () => Get.context, // or navigatorKey.currentContext
      enableLogging: true,
    ),
  );
  
  runApp(MyApp());
}
```

### 2. Send Request

```dart
import 'package:dio_http_util/http_util.dart';

// Send request
final response = await http.send(
  method: hm.post,
  path: '/auth/login',
  data: {'email': 'user@example.com', 'code': '123456'},
  queryParameters: {'source': 'mobile'},  // Optional: query parameters
  isLoading: true, // Optional: show loading indicator
);

// Handle response (errors are automatically handled and prompted)

// Method 1: Use extractField (simplest, recommended)
final token = response.extractField<String>('token');

// Method 2: Use extract (general method, supports complex logic)
final token2 = response.extract<String>(
  (data) => (data as Map)['token'] as String?,
);

// Method 3: Chain call (recommended, no intermediate variable)
final token3 = await http.send(
  method: hm.post,
  path: '/auth/login',
  data: {'email': 'user@example.com', 'code': '123456'},
).extractField<String>('token');

if (token != null) saveToken(token);
```

**send method parameters:**
- `method` - HTTP method (required, use `hm.get`, `hm.post`, etc.)
- `path` - Request path (required)
- `data` - Request body data (optional)
- `queryParameters` - URL query parameters (optional)
- `isLoading` - Whether to show loading indicator (default false)

**Notes:**
- If response fails (`isSuccess == false`), the tool will automatically call `onError` callback to show error prompt
- `extract` method internally checks `isSuccess`, returns `null` on failure
- `onSuccess` is optional, only used to make success logic clearer

## Data Extraction Methods

The package provides multiple data extraction methods to make data extraction simpler:

### 1. extractField - Extract Field (Simplest)

Extract field value directly from Map, no need to write lambda expression:

```dart
// Synchronous use
final token = response.extractField<String>('token');
final userId = response.extractField<int>('userId');

// Chain call (recommended)
final token = await http.send(...).extractField<String>('token');
```

### 2. extractModel - Extract Model

Convert from Map to model class, automatically handles type checking:

```dart
// Define model
class User {
  final String name;
  final int age;
  User({required this.name, required this.age});
  factory User.fromJson(Map<String, dynamic> json) {
    return User(name: json['name'], age: json['age']);
  }
}

// Use
final user = response.extractModel<User>(User.fromJson);

// Chain call (recommended)
final user = await http.send(...).extractModel<User>(User.fromJson);
```

### 3. extractList - Extract List

Extract list field from Map and convert to model list:

```dart
// Use
final users = response.extractList<User>('users', User.fromJson);

// Chain call (recommended)
final users = await http.send(...).extractList<User>('users', User.fromJson);
```

### 4. extractPath - Extract Nested Field

Support path extraction, such as `user.name`:

```dart
// Use
final userName = response.extractPath<String>('user.name');
final userId = response.extractPath<int>('user.profile.id');

// Chain call (recommended)
final userName = await http.send(...).extractPath<String>('user.name');
```

### 5. extract - General Extraction (Complex Scenarios)

Supports complex data extraction logic:

```dart
final complex = response.extract<CustomType>(
  (data) => CustomType.fromComplexData(data),
);
```

## Loading Indicator Feature

### Configure Loading Indicator

Configure `contextGetter` and optional `loadingWidgetBuilder` during initialization:

```dart
HttpUtil.configure(
  HttpConfig(
    baseUrl: 'https://api.example.com/v1',
    // Configure contextGetter (required)
    contextGetter: () => Get.context, // or navigatorKey.currentContext
    // Optional: Custom loading indicator UI
    loadingWidgetBuilder: (context) => MyCustomLoadingWidget(),
  ),
);
```

### Use Loading Indicator

Set `isLoading: true` when making request:

```dart
// Automatically show/hide loading indicator
final response = await http.send(
  method: hm.post,
  path: '/auth/login',
  data: {'email': 'user@example.com'},
  isLoading: true, // Automatically show loading indicator
);
```

### Custom Loading Indicator UI

```dart
HttpUtil.configure(
  HttpConfig(
    baseUrl: 'https://api.example.com/v1',
    contextGetter: () => Get.context,
    // Custom loading indicator Widget
    loadingWidgetBuilder: (context) => Container(
      color: Colors.black54,
      child: Center(
        child: CircularProgressIndicator(),
      ),
    ),
  ),
);
```

## Chain Calls

All extraction methods support chain calls, no intermediate variables needed:

```dart
// Extract field
final token = await http.send(...).extractField<String>('token');

// Extract model
final user = await http.send(...).extractModel<User>(User.fromJson);

// Extract list
final users = await http.send(...).extractList<User>('users', User.fromJson);

// Extract nested field
final userName = await http.send(...).extractPath<String>('user.name');

// Success/failure callbacks
await http.send(...)
  .onSuccess(() => print('Success'))
  .onFailure((error) => print('Failed: $error'));
```

## Custom Response Parser

### Simple Custom Parser

If only field names are different:

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

## API Documentation

### HttpConfig

| Parameter | Type | Description |
|-----------|------|-------------|
| `baseUrl` | `String` | Base URL (required) |
| `responseParser` | `ResponseParser?` | Response parser (optional, default `StandardResponseParser`) |
| `staticHeaders` | `Map<String, String>?` | Static request headers |
| `dynamicHeaderBuilder` | `Future<Map<String, String>> Function()?` | Dynamic request header builder |
| `networkErrorKey` | `String?` | Network error prompt message key (for internationalization) |
| `onError` | `void Function(String message)?` | Error prompt callback |
| `enableLogging` | `bool` | Whether to enable logging (default false) |
| `logPrintBody` | `bool` | Whether to print body (default true) |
| `logMode` | `LogMode` | Log mode: `complete` (recommended), `realTime`, `brief` |
| `logShowRequestHint` | `bool` | Whether to show brief hint on request (only effective in complete mode, default true) |
| `contextGetter` | `BuildContext? Function()?` | Context getter (for loading indicator feature) |
| `loadingWidgetBuilder` | `Widget Function(BuildContext)?` | Custom loading indicator Widget builder (optional) |

### Response<T>

Response abstract class, all response classes must inherit this.

**Required properties:**
- `bool get isSuccess` - Whether successful
- `String? get errorMessage` - Error message (if failed)
- `T? get data` - Data (if successful)

**Optional methods:**
- `handleError()` - Handle error (default implementation is empty, users can override in their own response class)

**Available methods (with default implementation):**
- `onSuccess(callback)` - Execute callback on success
- `onFailure(callback)` - Execute callback on failure
- `extract<R>(extractor)` - Extract and convert data (only executed on success)
- `extractField<R>(key)` - Extract field from Map (simplest way)
- `extractModel<R>(fromJson)` - Extract model from Map (type-safe)
- `extractList<R>(key, fromJson)` - Extract list from Map and convert to model list
- `extractPath<R>(path)` - Extract nested field from Map (supports path, e.g., 'user.name')
- `getData()` - Get data (type-safe, returns null on failure)

**Future extension methods (supports chain calls):**
- `Future<Response<T>>.extractField<R>(key)` - Chain call extract field
- `Future<Response<T>>.extractModel<R>(fromJson)` - Chain call extract model
- `Future<Response<T>>.extractList<R>(key, fromJson)` - Chain call extract list
- `Future<Response<T>>.extractPath<R>(path)` - Chain call extract nested field
- `Future<Response<T>>.extract<R>(extractor)` - Chain call general extract
- `Future<Response<T>>.onSuccess(callback)` - Chain call success callback
- `Future<Response<T>>.onFailure(callback)` - Chain call failure callback

### ResponseParser

Response parser interface, users must implement.

```dart
abstract class ResponseParser {
  Response<T> parse<T>(dio_package.Response response);
}
```

### HTTP Method Constants

```dart
hm.get
hm.post
hm.put
hm.delete
hm.patch
```

## License

MIT
