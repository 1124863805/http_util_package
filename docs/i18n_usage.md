# 多语言使用指南

## 方案说明

项目使用 **easy_localization** 实现多语言支持，这是 Flutter 中最完善的多语言解决方案之一。

## 优势

1. **JSON 格式** - 翻译文件使用 JSON，易于管理和维护
2. **类型安全** - 编译时检查翻译键是否存在
3. **参数化翻译** - 支持占位符和参数替换
4. **复数支持** - 支持复数形式的翻译
5. **日期/数字格式化** - 自动根据语言环境格式化
6. **持久化** - 语言选择会保存到本地存储
7. **动态切换** - 支持运行时切换语言，无需重启应用

## 文件结构

```
assets/
└── translations/
    ├── zh_CN.json  # 简体中文
    └── en_US.json  # 英文
```

## 使用方法

### 1. 基本使用

```dart
import 'package:easy_localization/easy_localization.dart';

// 方式一：使用 context.tr()
Text(context.tr('home'))

// 方式二：使用扩展方法（注意：与 GetX 的 tr 冲突，建议使用 context.tr()）
Text('home'.tr())
```

### 2. 带参数的翻译

在 JSON 文件中：
```json
{
  "welcome": "欢迎, {name}!",
  "items_count": "共有 {count} 个项目"
}
```

在代码中：
```dart
Text(context.tr('welcome', namedArgs: {'name': 'John'}))
Text(context.tr('items_count', namedArgs: {'count': '5'}))
```

### 3. 复数形式

在 JSON 文件中：
```json
{
  "item": "{count} item | {count} items"
}
```

在代码中：
```dart
Text('item'.plural(1))  // "1 item"
Text('item'.plural(5))  // "5 items"
```

### 4. 切换语言

```dart
import 'package:easy_localization/easy_localization.dart';
import 'app/services/locale_service.dart';

// 获取 LocaleService
final localeService = Get.find<LocaleService>();

// 切换到英文
await localeService.changeLocale(const Locale('en', 'US'));

// 切换到中文
await localeService.changeLocale(const Locale('zh', 'CN'));
```

## 添加新语言

1. 在 `assets/translations/` 目录下创建新的 JSON 文件，例如 `zh_TW.json`（繁体中文）
2. 复制现有翻译文件的内容并翻译
3. 在 `main.dart` 中添加支持的语言：
```dart
supportedLocales: const [
  Locale('zh', 'CN'), // 简体中文
  Locale('zh', 'TW'), // 繁体中文
  Locale('en', 'US'), // 英文
],
```
4. 在 `LocaleService` 中添加语言显示名称

## 最佳实践

1. **统一使用 context.tr()** - 避免与 GetX 的 tr 方法冲突
2. **翻译键命名规范** - 使用小写字母和下划线，如 `home_page_title`
3. **分组管理** - 在 JSON 文件中按功能模块分组注释
4. **及时更新** - 添加新功能时同步更新所有语言文件
5. **使用 LocaleHelper** - 统一使用辅助类进行翻译

## 注意事项

- GetX 的 `tr()` 方法和 easy_localization 的 `tr()` 方法冲突，建议统一使用 `context.tr()`
- 翻译键不存在时会返回键名本身，开发时注意检查
- 语言切换后需要重新构建相关页面才能看到效果
