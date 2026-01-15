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
- ✅ File download support - file download with progress callback, resume support, and cancellation
- ✅ OSS direct upload support - directly upload to object storage (Aliyun, Tencent Cloud, etc.), without going through backend server
- ✅ Server-Sent Events (SSE) support - real-time event stream processing
- ✅ Enhanced data extraction methods - simplified data extraction API
- ✅ Chain call support - Future extension methods for fluent chaining
- ✅ Automatic loading indicator - support automatic show/hide loading indicator
- ✅ Request deduplication/debouncing - prevent duplicate concurrent requests, supports deduplication, debounce, and throttle modes
- ✅ Request queue management - support request queue, priority, and concurrency limits

## Installation

```yaml
dependencies:
  dio_http_util: ^1.4.0
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
- `headers` - Request-specific headers (optional), will be merged with global headers, and will override global headers if keys are the same
- `priority` - Request priority (default 0), only effective when queue is enabled, higher number = higher priority
- `skipQueue` - Whether to skip queue (default false), if true, will execute directly even if queue is enabled
- `skipDeduplication` - Whether to skip deduplication (default false), if true, will execute directly even if deduplication is enabled

**Header priority (from low to high):**
1. Static headers (`staticHeaders`) - lowest priority
2. Dynamic headers (`dynamicHeaderBuilder`) - medium priority
3. Request-specific headers (`headers` parameter) - highest priority, will override global headers with the same key

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

**Note:** In chain calls, you only need to set `isLoading: true` in the first step, and the entire chain will share one loading indicator. See [Loading Indicator Management in Chain Calls](#loading-indicator-management-in-chain-calls) for details.

### Request-Specific Headers

If a specific endpoint requires specific headers instead of global ones, you can use the `headers` parameter:

```dart
// A specific endpoint requires specific headers
final response = await http.send(
  method: hm.post,
  path: '/special-endpoint',
  data: {'key': 'value'},
  headers: {
    'X-Custom-Header': 'custom-value',
    'X-API-Version': '2.0',
  }, // Request-specific headers, will override global headers with the same key
);

// Also supported in chain calls
final result = await http.send(
  method: hm.post,
  path: '/api/step1',
  headers: {'X-Step': '1'}, // Step 1 specific headers
)
.thenWith((prevResult) => http.send(
  method: hm.post,
  path: '/api/step2',
  headers: {'X-Step': '2'}, // Step 2 specific headers
));
```

**Header priority:**
- Request-specific headers (`headers` parameter) have the highest priority and will override global headers with the same key
- Dynamic headers (`dynamicHeaderBuilder`) have medium priority
- Static headers (`staticHeaders`) have the lowest priority

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

### Loading Indicator Management in Chain Calls

In chain calls, if you set `isLoading: true` in the first step, the entire chain will display **only one** loading indicator. The loading indicator will automatically close when the entire chain completes (success or failure).

**Usage:**

```dart
// Set isLoading: true in the first step, the entire chain shares one loading indicator
final result = await http.send(
  method: hm.post,
  path: '/uploader/generate',
  data: {'ext': 'jpg'},
  isLoading: true, // Only set in the first step, subsequent steps automatically inherit
)
.extractModel<FileUploadResult>(FileUploadResult.fromConfigJson)
.thenWith(
  (uploadResult) => http.uploadToUrlResponse(
    uploadUrl: uploadResult.uploadUrl,
    file: file,
    method: 'PUT',
    // No need to set isLoading, automatically reuses the loading indicator from the first step
  ),
)
.thenWithUpdate<String>(
  (uploadResult, uploadResponse) => http.send(
    method: hm.post,
    path: '/uploader/get-image-url',
    data: {'image_key': uploadResult.imageKey},
    // No need to set isLoading, automatically reuses the loading indicator from the first step
  ),
  (response) => response.extractField<String>('image_url'),
  (uploadResult, imageUrl) => uploadResult.copyWith(imageUrl: imageUrl),
);
// The loading indicator automatically closes when the entire chain completes
```

**Benefits:**
- ✅ Only need to set `isLoading: true` in the first step
- ✅ Subsequent steps automatically inherit, no need to repeat
- ✅ Only one loading indicator for the entire chain, avoiding flickering
- ✅ Automatically closes when the chain completes, no manual management needed
```

## File Download

### Basic Usage

**Parameters:**
- `path` - Request path (required)
  - Can be a relative path (e.g., `/api/download/file.pdf`), will use configured `baseUrl`
  - Can also be a full URL (e.g., `https://cdn.example.com/file.pdf`), will use the URL directly, ignoring `baseUrl`
- `savePath` - Full path to save the file (including filename, required)
- `queryParameters` - URL query parameters (optional, only effective when `path` is a relative path, query parameters for full URLs should be included in the URL)
- `headers` - Request-specific headers (optional)
  - If `path` is a relative path, will be merged with global headers, and will override global headers if keys are the same
  - If `path` is a full URL, only uses specific headers (does not merge with global headers)
- `onProgress` - Download progress callback `(received, total) => void` (optional)
- `cancelToken` - Cancel token (optional)
- `deleteOnError` - Whether to delete downloaded file on error (default true)
- `resumeOnError` - Whether to support resume download (default true)

**Return Value:**
- Returns `Future<DownloadResponse<String>>`, where `data` field is the file path
- Check success with `response.isSuccess`
- Get file path with `response.filePath`
- Get total bytes with `response.totalBytes`

**Example (Relative Path):**
```dart
import 'dart:io';
import 'package:dio_http_util/http_util.dart';
import 'package:path_provider/path_provider.dart';

// Get save path
final directory = await getApplicationDocumentsDirectory();
final savePath = '${directory.path}/downloaded_file.pdf';

// Download file (using baseUrl)
final response = await http.downloadFile(
  path: '/api/download/file.pdf',
  savePath: savePath,
  onProgress: (received, total) {
    if (total > 0) {
      print('Download progress: ${(received / total * 100).toStringAsFixed(1)}%');
    }
  },
);

if (response.isSuccess) {
  print('Download successful, file path: ${response.filePath}');
  print('File size: ${response.totalBytes} bytes');
} else {
  print('Download failed: ${response.errorMessage}');
}
```

**Example (Full URL):**
```dart
// Download from CDN or other server, independent of baseUrl
final response = await http.downloadFile(
  path: 'https://cdn.example.com/files/file.pdf',
  savePath: '/path/to/save/file.pdf',
  headers: {'X-Custom-Header': 'value'}, // Only uses specific headers for full URLs
  onProgress: (received, total) {
    if (total > 0) {
      print('Download progress: ${(received / total * 100).toStringAsFixed(1)}%');
    }
  },
);

if (response.isSuccess) {
  print('Download successful');
}
```

### Resume Download

If download fails, you can enable resume download feature. When called again, it will automatically resume from the breakpoint:

```dart
// First download (may fail)
final response1 = await http.downloadFile(
  path: '/api/download/large-file.zip',
  savePath: '/path/to/save/large-file.zip',
  resumeOnError: true, // Enable resume download
  onProgress: (received, total) {
    print('Download progress: ${(received / total * 100).toStringAsFixed(1)}%');
  },
);

// If download fails, calling again will automatically resume from breakpoint
if (!response1.isSuccess) {
  print('Download failed, trying to resume...');
  final response2 = await http.downloadFile(
    path: '/api/download/large-file.zip',
    savePath: '/path/to/save/large-file.zip',
    resumeOnError: true,
    onProgress: (received, total) {
      print('Resume progress: ${(received / total * 100).toStringAsFixed(1)}%');
    },
  );
  
  if (response2.isSuccess) {
    print('Resume download successful');
  }
}
```

**Resume Download Notes:**
- If `resumeOnError` is true, calling again with the same path and save path will automatically resume from the breakpoint
- Resume download is implemented using HTTP Range header
- If the file already exists and is complete, it will return success directly without re-downloading
- The server must support Range requests (most servers do)

### Cancel Download

```dart
import 'package:dio/dio.dart' as dio_package;

// Create cancel token
final cancelToken = dio_package.CancelToken();

// Download file
final response = await http.downloadFile(
  path: '/api/download/file.pdf',
  savePath: '/path/to/save/file.pdf',
  cancelToken: cancelToken,
  onProgress: (received, total) {
    print('Download progress: ${(received / total * 100).toStringAsFixed(1)}%');
  },
);

// Cancel download (e.g., user clicks cancel button)
cancelToken.cancel('User cancelled download');
```

### Request-Specific Headers

```dart
final response = await http.downloadFile(
  path: '/api/download/private-file.pdf',
  savePath: '/path/to/save/file.pdf',
  headers: {'X-Download-Type': 'private'}, // Request-specific headers
);
```

### Notes

- **Path Type**:
  - Relative paths (e.g., `/api/download/file.pdf`) will use configured `baseUrl` and global headers
  - Full URLs (e.g., `https://cdn.example.com/file.pdf`) will use the URL directly, ignoring `baseUrl` and global headers
  - Query parameters for full URLs should be included in the URL, the `queryParameters` parameter will be ignored
- Save directory will be automatically created if it doesn't exist
- Downloaded file will be automatically deleted on error by default (can be disabled with `deleteOnError: false`)
- The `total` in progress callback may be -1 (unknown size), need to handle in callback
- For large file downloads, it's recommended to enable resume download to avoid re-downloading on network interruption
- The save path must include the filename, not just the directory path

## Request Deduplication/Debouncing

### Overview

Request deduplication/debouncing prevents duplicate concurrent requests from being sent multiple times. It supports three modes:

- **Deduplication Mode**: Same requests share the same Future, avoiding duplicate requests
- **Debounce Mode**: Delays execution, if a new request comes during the delay, cancels the old request and executes the new one
- **Throttle Mode**: Executes only once within a specified time interval

### Configuration

Configure deduplication/debouncing during initialization:

```dart
HttpUtil.configure(
  HttpConfig(
    baseUrl: 'https://api.example.com/v1',
    // Configure request deduplication/debouncing
    deduplicationConfig: DeduplicationConfig(
      mode: DeduplicationMode.deduplication, // Deduplication mode
      debounceDelay: Duration(milliseconds: 300), // Debounce delay (only effective in debounce mode)
      throttleInterval: Duration(milliseconds: 300), // Throttle interval (only effective in throttle mode)
    ),
  ),
);
```

### Usage Examples

**Deduplication Mode** (Recommended):
```dart
// Configuration
deduplicationConfig: DeduplicationConfig(
  mode: DeduplicationMode.deduplication,
),

// Usage: Same requests are automatically deduplicated
final response1 = http.send(method: hm.get, path: '/api/data');
final response2 = http.send(method: hm.get, path: '/api/data'); // Will reuse response1's Future
```

**Debounce Mode**:
```dart
// Configuration
deduplicationConfig: DeduplicationConfig(
  mode: DeduplicationMode.debounce,
  debounceDelay: Duration(milliseconds: 500),
),

// Usage: When called rapidly in succession, only the last call is executed
// Example: When user types search keywords rapidly, only the last request is sent
```

**Throttle Mode**:
```dart
// Configuration
deduplicationConfig: DeduplicationConfig(
  mode: DeduplicationMode.throttle,
  throttleInterval: Duration(seconds: 1),
),

// Usage: Executes only once within the specified time interval
// Example: Prevents users from clicking buttons too frequently
```

**Skip Deduplication**:
```dart
// Some requests need to be sent forcefully, even if identical
final response = await http.send(
  method: hm.post,
  path: '/api/refresh',
  skipDeduplication: true, // Skip deduplication
);
```

## Request Queue Management

### Overview

Request queue management controls the execution order and concurrency of requests, supporting:

- **Priority Queue**: Higher priority requests execute first
- **Concurrency Limit**: Limits the number of concurrent requests
- **Queue Control**: Supports pause/resume queue, clear queue

### Configuration

Configure request queue during initialization:

```dart
HttpUtil.configure(
  HttpConfig(
    baseUrl: 'https://api.example.com/v1',
    // Configure request queue
    queueConfig: QueueConfig(
      enabled: true, // Enable queue
      maxConcurrency: 5, // Max concurrency (default 10)
    ),
  ),
);
```

### Usage Examples

**Basic Usage**:
```dart
// After configuring queue, all requests automatically enter the queue
final response = await http.send(
  method: hm.get,
  path: '/api/data',
  priority: 10, // Set priority (higher number = higher priority, default 0)
);
```

**Priority Example**:
```dart
// High priority request (executes first)
final urgentResponse = await http.send(
  method: hm.post,
  path: '/api/urgent',
  priority: 100,
);

// Normal priority request
final normalResponse = await http.send(
  method: hm.get,
  path: '/api/normal',
  priority: 0, // Default priority
);
```

**Skip Queue**:
```dart
// Urgent request, skip queue and execute directly
final urgentResponse = await http.send(
  method: hm.post,
  path: '/api/emergency',
  skipQueue: true, // Skip queue
);
```

**Queue Status Monitoring**:
```dart
// Get queue manager (requires queueConfig to be configured first)
final queue = HttpUtil.requestQueue;
if (queue != null) {
  // Monitor queue status
  queue.statusStream.listen((status) {
    print('Queue length: ${status.queueLength}');
    print('Running: ${status.runningCount}');
    print('Paused: ${status.isPaused}');
  });
  
  // Pause queue
  queue.pause();
  
  // Resume queue
  queue.resume();
  
  // Clear queue
  queue.clear();
}
```

### Combined Usage

Request deduplication and queue management can be used together:

```dart
HttpUtil.configure(
  HttpConfig(
    baseUrl: 'https://api.example.com/v1',
    // Enable both deduplication and queue
    deduplicationConfig: DeduplicationConfig(
      mode: DeduplicationMode.deduplication,
    ),
    queueConfig: QueueConfig(
      enabled: true,
      maxConcurrency: 5,
    ),
  ),
);

// Usage: Requests first enter the queue, then deduplication is applied within the queue
final response = await http.send(
  method: hm.get,
  path: '/api/data',
  priority: 10,
  // skipQueue: true, // Can skip queue
  // skipDeduplication: true, // Can skip deduplication
);
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
| `deduplicationConfig` | `DeduplicationConfig?` | Request deduplication/debouncing configuration (optional) |
| `queueConfig` | `QueueConfig?` | Request queue configuration (optional) |

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
- `Future<Response<T>>.then<R>(nextRequest)` - Chain call to next request (pass previous response)
- `Future<Response<T>>.thenIf<R>(condition, nextRequest)` - Conditional chain call

**Extracted value chain call extensions:**
- `Future<M?>.thenWith<R>(nextRequest)` - Pass extracted object to next request, returns `ChainResult`
- `Future<M?>.thenWithExtract<R>(nextRequest, finalExtractor)` - Pass extracted object and extract final result

**ChainResult chain call methods:**
- `ChainResult<M, R>.thenWith<R2>(nextRequest)` - Continue chain call (intermediate step), returns `ChainResult`
- `ChainResult<M, R>.thenWithUpdate<R2>(nextRequest, extractor, updater)` - Continue chain call (final step), update object and return
- `ChainResult<M, R>.thenWithExtract<R2>(nextRequest, finalExtractor)` - Continue chain call and extract final result

**Future<ChainResult> extension methods:**
- `Future<ChainResult<M, R>>.thenWith<R2>(nextRequest)` - Continue chain call (intermediate step)
- `Future<ChainResult<M, R>>.thenWithUpdate<R2>(nextRequest, extractor, updater)` - Continue chain call (final step)

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

### Get Dio Instance

```dart
// Get configured instance
final dio = HttpUtil.dio;

// Create independent instance (optional parameters)
final customDio = HttpUtil.createDio(
  baseUrl: 'https://other-api.com',
  connectTimeout: Duration(seconds: 10),
  receiveTimeout: Duration(seconds: 10),
  sendTimeout: Duration(seconds: 10),
);
```

### Get Request Queue Manager

```dart
// Get request queue manager (if queueConfig is configured)
final queue = HttpUtil.requestQueue;
if (queue != null) {
  // Monitor queue status
  queue.statusStream.listen((status) {
    print('Queue length: ${status.queueLength}');
    print('Running: ${status.runningCount}');
  });
  
  // Pause/resume queue
  queue.pause();
  queue.resume();
  
  // Clear queue
  queue.clear();
}
```

## License

MIT
