# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-01-XX

### Added
- Initial release
- HTTP request utility based on Dio
- Configurable header injection (static and dynamic)
- Unified API response wrapper (`ApiResponse<T>`)
- Automatic error handling with customizable callbacks
- Type-safe HTTP method constants (`hm` class)
- Support for GET, POST, PUT, DELETE, PATCH methods
- Request/response interceptors
- Global `http` instance for simplified usage

### Features
- `HttpConfig` class for flexible configuration
- Static headers support
- Dynamic header builder for runtime header generation
- Custom error handler callback
- Network error handling
- 500 error detection and handling
- Response status code validation (all codes treated as valid)
