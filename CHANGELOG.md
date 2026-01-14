# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
