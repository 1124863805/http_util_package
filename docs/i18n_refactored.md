# 多语言模块重构说明

## 重构内容

根据 `easy_localization` 官方文档，对多语言模块进行了全面重构和优化。

## 主要改进

### 1. LocaleService 优化

#### 改进前
- 手动管理 GetStorage 保存语言设置
- 手动解析字符串创建 Locale
- 缺少设备语言环境支持

#### 改进后
- 使用 `easy_localization` 的扩展方法（`setLocale`, `resetLocale` 等）
- 利用 `easy_localization` 自动保存功能（`saveLocale: true`）
- 添加设备语言环境支持（`deviceLocale`）
- 使用字符串扩展方法（`toLocale()`, `toStringWithSeparator()`）

```dart
// 切换语言（自动保存）
await localeService.changeLocale(const Locale('en', 'US'));

// 重置到设备语言环境
await localeService.resetLocale();

// 获取设备语言环境
final deviceLocale = localeService.deviceLocale;

// 清除保存的语言设置
await localeService.deleteSaveLocale();
```

### 2. LocaleHelper 优化

#### 改进前
- 只提供基本的翻译方法
- 缺少复数支持
- 缺少参数格式化

#### 改进后
- 推荐使用 `context.tr()` 方法（避免与 GetX 冲突）
- 支持复数翻译（`plural()`）
- 支持参数格式化（`NumberFormat`）
- 支持性别切换（`gender`）

```dart
// 基本翻译
LocaleHelper.tr(context, LocaleKeys.settings)

// 带参数翻译
LocaleHelper.trWithArgs(context, 'welcome', {'name': 'John'})

// 复数翻译
LocaleHelper.plural(context, 'item', 5)

// 复数翻译（带格式化）
LocaleHelper.plural(context, 'money', 1000000, 
  format: NumberFormat.compact(locale: context.locale.toString()))
```

### 3. main.dart 配置优化

#### 新增配置项
- `saveLocale: true` - 自动保存语言设置
- `useFallbackTranslations: true` - 使用回退翻译
- `useFallbackTranslationsForEmptyResources: true` - 空资源时使用回退翻译

#### 配置说明
```dart
EasyLocalization(
  supportedLocales: LocaleService.supportedLocales,
  path: 'assets/translations',
  fallbackLocale: LocaleService.fallbackLocale,
  assetLoader: const CodegenLoader(),
  saveLocale: true, // 自动保存语言设置
  useFallbackTranslations: true, // 使用回退翻译
  useFallbackTranslationsForEmptyResources: true, // 空资源时使用回退翻译
  child: MyApp(),
)
```

## 使用示例

### 1. 基本翻译

```dart
import 'package:easy_localization/easy_localization.dart';
import '../../../generated/locale_keys.g.dart';

// 推荐方式：使用 context.tr()
Text(context.tr(LocaleKeys.settings))

// 或者使用 LocaleHelper
Text(LocaleHelper.tr(context, LocaleKeys.settings))
```

### 2. 带参数翻译

```dart
// JSON: "welcome": "欢迎, {name}!"
Text(context.tr('welcome', namedArgs: {'name': 'John'}))

// JSON: "msg": "{} are written in the {} language"
Text(context.tr('msg', args: ['Easy localization', 'Dart']))
```

### 3. 复数翻译

```dart
// JSON: "item": {"zero": "no items", "one": "{} item", "other": "{} items"}
Text(context.plural('item', count))

// 带格式化
Text(context.plural('money', 1000000, 
  format: NumberFormat.compact(locale: context.locale.toString())))
```

### 4. 性别切换

```dart
// JSON: "gender": {"male": "Hi man", "female": "Hello girl"}
Text(context.tr('gender', gender: isMale ? 'male' : 'female'))
```

### 5. 语言切换

```dart
final localeService = Get.find<LocaleService>();

// 切换语言
await localeService.changeLocale(const Locale('en', 'US'));

// 重置到设备语言环境
await localeService.resetLocale();

// 获取设备语言环境
print(localeService.deviceLocale?.toString());

// 清除保存的语言设置
await localeService.deleteSaveLocale();
```

## 最佳实践

1. **优先使用 context.tr()** - 避免与 GetX 的 tr 方法冲突
2. **使用 LocaleKeys** - 类型安全，避免拼写错误
3. **使用 CodegenLoader** - 编译时加载，性能更好
4. **启用回退翻译** - 确保所有键都有翻译
5. **使用扩展方法** - 简化 Locale 转换

## 迁移指南

### 旧代码
```dart
// 旧方式
final storage = GetStorage();
await storage.write('app_locale', 'en_US');
final saved = storage.read<String>('app_locale');
```

### 新代码
```dart
// 新方式（自动保存）
await context.setLocale(const Locale('en', 'US'));
final current = context.locale;
```

## 性能优化

1. **CodegenLoader** - 编译时加载所有翻译，运行时无需读取文件
2. **自动保存** - 使用 `saveLocale: true`，无需手动管理存储
3. **回退翻译** - 减少翻译缺失的情况

## 注意事项

1. **不要手动编辑生成的文件** - `lib/generated/` 目录下的文件会在重新生成时被覆盖
2. **及时重新生成** - 修改翻译文件后记得运行生成命令
3. **使用 context.tr()** - 避免与 GetX 的 tr 方法冲突
4. **启用回退翻译** - 确保应用在所有语言环境下都能正常工作
