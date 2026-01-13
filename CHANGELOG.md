# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
