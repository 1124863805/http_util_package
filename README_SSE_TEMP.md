## Server-Sent Events (SSE)

### 基本使用

使用 `sseManager()` 创建连接管理器，支持单连接和多连接场景。

**单连接场景**：
```dart
import 'package:dio_http_util/http_util.dart';

final manager = http.sseManager();

// 建立连接
await manager.connect(
  id: 'chat',
  path: '/ai/chat/stream',
  method: 'POST',
  data: {'question': '你好'},
  onData: (event) {
    print('收到事件: ${event.data}');
  },
  onError: (error) {
    print('SSE 错误: $error');
  },
  onDone: () {
    print('SSE 连接关闭');
  },
);

// 断开连接
await manager.disconnect('chat');
```

**多连接场景**：
```dart
final manager = http.sseManager();

// 建立第一个连接
await manager.connect(
  id: 'chat',
  path: '/ai/chat/stream',
  method: 'POST',
  data: {'question': '你好'},
  onData: (event) => print('聊天: ${event.data}'),
);

// 建立第二个连接
await manager.connect(
  id: 'notifications',
  path: '/notifications/stream',
  onData: (event) => print('通知: ${event.data}'),
);

// 断开指定连接
await manager.disconnect('chat');

// 断开所有连接
await manager.disconnectAll();
```

### 完整示例：实时聊天页面

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio_http_util/http_util.dart';

class ChatController extends GetxController {
  final sseMessage = ''.obs;
  final isSSEConnected = false.obs;
  SSEManager? _sseManager;

  @override
  void onInit() {
    super.onInit();
    _sseManager = http.sseManager();
  }

  @override
  void onClose() {
    _sseManager?.disconnectAll();
    super.onClose();
  }

  Future<void> connectSSE(String question) async {
    try {
      isSSEConnected.value = true;
      sseMessage.value = '';

      await _sseManager!.connect(
        id: 'chat',
        path: '/ai/chat/stream',
        method: 'POST',
        data: {'question': question},
        onData: (event) {
          sseMessage.value += event.data;
        },
        onError: (error) {
          isSSEConnected.value = false;
          Get.snackbar('错误', 'SSE 连接错误: $error');
        },
        onDone: () {
          isSSEConnected.value = false;
        },
      );
    } catch (e) {
      isSSEConnected.value = false;
      Get.snackbar('错误', 'SSE 连接失败: $e');
    }
  }

  Future<void> disconnectSSE() async {
    await _sseManager?.disconnect('chat');
    isSSEConnected.value = false;
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
  
  /// 事件 ID（可选）
  final String? id;
  
  /// 重试间隔（毫秒，可选）
  final int? retry;
  
  SSEEvent({
    required this.data,
    this.event,
    this.id,
    this.retry,
  });
}
```

**字段说明：**
- `data` - 事件数据（必需），可能包含多行数据（用换行符分隔）
- `event` - 事件类型（可选），用于区分不同类型的事件
- `id` - 事件 ID（可选），用于重连时指定最后接收的事件
- `retry` - 重试间隔（毫秒，可选），服务器建议的重连间隔

### SSE 管理器 API

| 方法/属性 | 类型 | 说明 |
|----------|------|------|
| `connect()` | `Future<String>` | 建立 SSE 连接，返回连接 ID |
| `disconnect(id)` | `Future<void>` | 断开指定连接 |
| `disconnectAll()` | `Future<void>` | 断开所有连接 |
| `hasConnection(id)` | `bool` | 检查连接是否存在 |
| `isConnected(id)` | `bool` | 检查连接是否已连接 |
| `connectionIds` | `List<String>` | 获取所有连接 ID |
| `connectionCount` | `int` | 获取连接数量 |
| `dispose()` | `Future<void>` | 清理所有资源（等同于 `disconnectAll()`） |

**参数说明：**
- `id` - 连接唯一标识符（必需），用于管理多个连接
- `path` - 请求路径（必需）
- `method` - HTTP 方法，默认为 'GET'，支持 'GET' 和 'POST'
- `data` - 请求体数据（POST 请求时使用，会自动转换为 JSON）
- `queryParameters` - URL 查询参数（可选）
- `onData` - 数据回调（必需）
- `onError` - 错误回调（可选）
- `onDone` - 完成回调（可选）
- `replaceIfExists` - 如果连接已存在，是否替换（默认 true）

**注意：**
- SSE 连接会自动使用配置的请求头（静态和动态）
- 连接建立后，服务器会持续推送事件
- 连接失败时会自动清理资源，无需手动处理
- 在 Controller 的 `onClose` 中调用 `disconnectAll()` 可以自动清理所有连接
- 支持同时维护多个连接，每个连接有唯一 ID
