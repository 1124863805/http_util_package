# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.4.1] - 2026-01-15

### Added
- **多服务支持（多 baseUrl）**
  - 新增 `serviceBaseUrls` 配置，支持在 `HttpConfig` 中配置多个服务的 baseUrl
  - `send` 方法新增 `baseUrl` 和 `service` 参数，支持灵活选择使用哪个服务
  - baseUrl 选择优先级：直接指定的 `baseUrl` 参数 > `service` 参数 > 默认 `baseUrl`
  - 自动为不同 baseUrl 创建和缓存独立的 Dio 实例，复用拦截器配置
  - 文件上传、文件下载、SSE 等功能均支持多服务
  - 请求去重逻辑已更新，基于完整 URL（包含 baseUrl）进行去重
- **SSE 多连接完成跟踪**
  - 新增 `waitForAllConnectionsDone()` 方法，支持等待所有 SSE 连接完成
  - 自动跟踪每个连接的完成状态，当所有连接的 `onDone` 回调被调用时 resolve
  - 支持在多个连接场景下统一处理所有连接的完成事件

### 改进
- 优化了 Dio 实例管理，为不同 baseUrl 自动创建独立实例
- 优化了 SSE 连接管理，支持跟踪和等待所有连接完成
- 更新了文档，添加了多服务支持和 SSE 多连接完成跟踪的完整说明和示例
- 完善了 API 文档，添加了 `serviceBaseUrls` 和相关参数的说明

## [1.4.0] - 2026-01-15

### Added
- **请求去重/防抖功能**
  - 新增 `RequestDeduplicator` 类，支持请求去重、防抖、节流三种模式
  - 支持在 `HttpConfig` 中配置 `deduplicationConfig` 来启用去重/防抖功能
  - 支持 `skipDeduplication` 参数，可以跳过去重直接执行请求
  - 去重模式：相同请求共享同一个 Future，避免重复请求
  - 防抖模式：延迟执行，如果在延迟期间有新请求，取消旧请求，执行新请求
  - 节流模式：在指定时间内只执行一次
- **请求队列管理功能**
  - 新增 `RequestQueue` 类，支持请求队列、优先级、并发数限制
  - 支持在 `HttpConfig` 中配置 `queueConfig` 来启用队列管理
  - 支持 `priority` 参数，设置请求优先级（数字越大优先级越高）
  - 支持 `skipQueue` 参数，可以跳过队列直接执行请求
  - 支持队列状态监听（`statusStream`）
  - 支持暂停/恢复队列、清空队列
  - 新增 `HttpUtil.requestQueue` getter，获取队列管理器实例

### 改进
- 优化了请求执行流程，支持去重和队列的组合使用
- 更新了文档，添加了请求去重和队列管理的完整说明和示例
- 完善了 API 文档，添加了新参数的说明

## [1.3.0] - 2026-01-15

### Added
- **文件下载功能**
  - 新增 `downloadFile()` 方法，支持文件下载
  - 支持下载进度回调，实时显示下载进度
  - 支持断点续传，下载失败后可以继续下载
  - 支持取消下载，通过 `CancelToken` 取消下载操作
  - 支持特定请求头，可以为单个下载请求设置特定的请求头
  - 自动创建保存目录，如果目录不存在会自动创建
  - 下载失败时自动删除已下载的文件（可配置）
  - 新增 `DownloadResponse` 类，用于表示下载结果

### 改进
- 优化了文件下载的错误处理，提供更详细的错误信息
- 更新了文档，添加了文件下载功能的完整说明和示例

## [1.2.6] - 2026-01-15

### Added
- Added `headers` parameter support to `uploadFile()` method for request-specific headers
- Added `headers` parameter support to `uploadFiles()` method for request-specific headers
- Added `headers` parameter support to `sseManager().connect()` method for request-specific headers in SSE connections

### Changed
- Updated documentation to include `headers` parameter examples for file upload and SSE methods

## [1.2.5] - 2026-01-15

### Added
- **支持特定请求的请求头**
  - 在 `send` 方法中添加了 `headers` 参数，支持为单个请求设置特定的请求头
  - 特定请求头会与全局请求头合并，如果键相同则覆盖全局请求头
  - 请求头优先级：特定请求头 > 动态请求头 > 静态请求头
  - 支持在链式调用中为每个步骤设置不同的请求头

### 改进
- 优化了请求拦截器的逻辑，确保特定请求头的优先级最高
- 更新了文档，添加了特定请求头的使用示例和说明

## [1.2.4] - 2026-01-15

### Fixed
- **修复 onSuccess/onFailure 方法中 loading 不关闭的问题**
  - 修复了使用 `.onSuccess()` 或 `.onFailure()` 方法时，loading 提示无法自动关闭的问题
  - 现在 `onSuccess` 和 `onFailure` 方法会在回调执行后自动关闭 loading 提示
  - 这两个方法是链式调用的终点，不会继续发送新的请求，因此应该关闭 loading

### 改进
- 优化了 `onSuccess` 和 `onFailure` 方法的实现，确保 loading 提示能正确关闭
- 使用 `Future.microtask` 确保在回调执行后再关闭 loading，避免时序问题

## [1.2.3] - 2026-01-15

### Fixed
- **修复 SSE POST 请求中文字符编码问题**
  - 修复了 SSE POST 请求中包含中文字符时出现 "Invalid argument (string): Contains invalid characters" 错误的问题
  - 现在使用 `utf8.encode()` 正确编码 JSON 字符串为字节后再写入请求体
  - 支持在 POST 请求体中发送包含中文的 JSON 数据

### Changed
- **简化 SSE API，统一使用 sseManager()**
  - 移除了 `sse()`, `sseClient()`, `sseConnection()`, `sseWithCallbacks()` 方法
  - 现在只保留 `sseManager()` 方法作为唯一的 SSE API
  - `sseManager()` 支持单连接和多连接场景，功能更强大
  - 简化了 API 设计，降低了学习成本

### 改进
- 优化了 SSE 连接管理器的实现，直接使用 `SSEConnection.connect()` 建立连接
- 更新了文档，移除了旧的 SSE 方法说明，只保留 `sseManager()` 的完整文档
- 完善了多连接场景的使用示例

## [1.2.2] - 2026-01-15

### Fixed
- **修复链式调用的加载提示管理问题**
  - 修复了链式调用中第一步设置 `isLoading: true` 时，加载提示无法被后续步骤复用的问题
  - 现在链式调用会正确地在第一步创建加载提示，并在整个链路结束时关闭
  - 修复了单次请求（没有后续链式调用）时，加载提示无法关闭的问题
  - 优化了加载提示的生命周期管理，确保在各种场景下都能正确显示和关闭

### 改进
- 优化了 `send` 方法中链式调用加载提示的创建和复用逻辑
- 在 `extractField` 方法中添加了延迟检查机制，确保单次请求的加载提示能正确关闭
- 完善了代码注释，明确链式调用和单次请求的处理方式

## [1.2.1] - 2026-01-15

### Fixed
- **修复单次请求的加载提示无法关闭问题**
  - 修复了单次请求（非链式调用）时，加载提示无法自动关闭的 bug
  - 单次请求现在会正确地在请求结束时关闭加载提示
  - 链式调用的加载提示管理逻辑保持不变

### 改进
- 优化了 `send` 方法中加载提示的管理逻辑，区分单次请求和链式调用
- 完善了代码注释，明确单次请求和链式调用的处理方式

## [1.2.0] - 2026-01-15

### Added
- **数据提取增强功能**
  - `extractField<R>(key)` - 从 Map 中提取字段（最简单的方式）
  - `extractModel<R>(fromJson)` - 从 Map 提取模型（类型安全）
  - `extractList<R>(key, fromJson)` - 从 Map 提取列表并转换为模型列表
  - `extractPath<R>(path)` - 从 Map 提取嵌套字段（支持路径，如 'user.name'）
- **Future 扩展方法（链式调用支持）**
  - `Future<Response<T>>.extractField<R>(key)` - 链式调用提取字段
  - `Future<Response<T>>.extractModel<R>(fromJson)` - 链式调用提取模型
  - `Future<Response<T>>.extractList<R>(key, fromJson)` - 链式调用提取列表
  - `Future<Response<T>>.extractPath<R>(path)` - 链式调用提取嵌套字段
  - `Future<Response<T>>.extract<R>(extractor)` - 链式调用通用提取
  - `Future<Response<T>>.onSuccess(callback)` - 链式调用成功回调
  - `Future<Response<T>>.onFailure(callback)` - 链式调用失败回调
  - `thenWith()` - 链式调用中间步骤，传递提取的对象和响应
  - `thenWithUpdate()` - 链式调用最后一步，提取并更新对象
  - `thenWithExtract()` - 链式调用并提取最终结果
- **加载提示功能**
  - `isLoading` 参数：在 `send()` 方法中支持自动显示/隐藏加载提示
  - `contextGetter` 配置：在 `HttpConfig` 中配置 BuildContext 获取器
  - `loadingWidgetBuilder` 配置：支持自定义加载提示 UI
  - `DefaultLoadingWidget`：默认 iOS 风格加载提示组件
  - **链式调用中的加载提示管理**：在链式调用中，只需在第一步设置 `isLoading: true`，整个链路共享一个加载提示，链路结束时自动关闭

### Features
- 数据提取增强 - 提供多种简化方法，让数据提取更简单
- 链式调用支持 - Future 扩展方法，支持流畅的链式调用
- 自动加载提示 - 支持自动显示/隐藏加载提示，无需手动管理
- 链式调用加载提示管理 - 整个链路只显示一个加载提示，自动管理生命周期

### 改进
- 优化数据提取 API，提供更简洁的使用方式
- 完善文档，添加所有新功能的使用示例
- 改进代码结构，提取加载提示组件到独立文件
- 优化链式调用中的加载提示管理，确保加载提示在整个链路结束时正确关闭

## [1.1.0] - 2026-01-14

### Added
- **文件上传支持**
  - `uploadFile()` 方法：单文件上传，支持 File、String 路径、Uint8List 字节数组
  - `uploadFiles()` 方法：多文件上传
  - `UploadFile` 类：文件上传辅助类，支持自定义字段名、文件名、Content-Type
  - 支持上传进度回调
  - 支持额外表单数据
- **OSS 直传支持**
  - `uploadToUrlResponse()` 方法：直接上传到外部 URL（阿里云 OSS、腾讯云 COS 等），支持链式调用
  - 支持 PUT 和 POST 方法
  - 支持自定义请求头
  - 不依赖 baseUrl 配置，直接使用完整 URL
- **Server-Sent Events (SSE) 支持**
  - `sse()` 方法：自动连接并返回事件流（推荐使用）
  - `sseClient()` 方法：手动控制连接（高级用法）
  - `SSEClient` 类：SSE 客户端封装
  - `SSEEvent` 类：SSE 事件模型
  - `SSEStream` 类：SSE 流处理逻辑
  - 自动复用配置的请求头（静态和动态）

### Features
- 文件上传支持 - 单文件、多文件上传，支持进度回调
- OSS 直传支持 - 直接上传到对象存储，不经过后端服务器
- Server-Sent Events (SSE) 支持 - 实时事件流处理

### 改进
- 优化 SSE API，提供自动连接方式，简化使用
- 完善文档，添加文件上传、OSS 直传、SSE 的详细使用示例

## [1.0.2] - 2026-01-13

### 改进
- 完善文档，添加智能解析器示例（处理不规范的响应结构和分页结构）
- 补充所有示例代码的导入语句
- 完善 API 文档，添加缺失的参数说明（`networkErrorKey`, `logShowRequestHint`）
- 补充 `Response<T>` 接口文档，添加 `handleError()` 方法说明
- 完善 `PagedResponse` 类示例代码

## [1.0.1] - 2026-01-13

### 🚀 初始版本：基于接口的完全灵活设计

### Added
- **Response<T> 抽象类**：核心响应接口，所有响应类必须继承此类
  - 提供统一的便利方法：`onSuccess`, `onFailure`, `extract`, `getData`
  - 用户完全控制响应类的结构
- **ResponseParser 接口**：用户必须实现此接口来定义如何解析 API 响应
- **PathBasedResponseParser**：支持根据请求路径选择不同的解析器
- **PathMatcher**：路径匹配规则，支持正则表达式和字符串匹配
- **StandardResponseParser**：标准响应解析器示例（在 `parsers/` 目录）
- **ApiResponse**：API 响应封装类的示例实现，展示如何继承 `Response<T>`
- **SimpleErrorResponse**：简单的错误响应实现（内部使用）
- **HttpConfig**：配置类，支持静态和动态请求头注入
- **HttpUtil**：HTTP 请求工具类，基于 Dio 封装
- **LogInterceptor**：日志拦截器，支持多种日志模式
- **HTTP 方法常量**：类型安全的 HTTP 方法常量（`hm` 类）

### Features
- 完全灵活的响应解析 - 支持任意响应结构，零假设设计
- 用户自定义响应类 - 通过 `Response<T>` 抽象类完全控制响应结构
- 统一的便利方法 - 所有响应类都提供 `onSuccess`, `onFailure`, `extract`, `getData` 方法
- 自动错误处理和提示
- 类型安全的 HTTP 方法常量
- 简洁的 API 设计
- 支持静态和动态请求头注入
- 支持日志打印（可配置）
- 支持创建独立的 Dio 实例
