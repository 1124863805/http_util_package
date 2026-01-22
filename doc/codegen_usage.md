# 代码生成使用指南

## 概述

项目已配置使用 `easy_localization` 的代码生成功能，提供：
- **CodegenLoader**: 编译时资源加载器，提高性能
- **LocaleKeys**: 类型安全的翻译键，避免拼写错误

## 生成的文件

生成的文件位于 `lib/generated/` 目录：
- `codegen_loader.g.dart` - 资源加载器
- `locale_keys.g.dart` - 翻译键常量

## 重新生成

当修改翻译文件后，需要重新生成代码：

```bash
# 生成资源加载器
flutter pub run easy_localization:generate -S assets/translations -O lib/generated

# 生成翻译键
flutter pub run easy_localization:generate -S assets/translations -O lib/generated -f keys -o locale_keys.g.dart
```

## 使用方法

### 1. 使用 CodegenLoader（已在 main.dart 配置）

```dart
import 'generated/codegen_loader.g.dart';

EasyLocalization(
  // ...
  assetLoader: const CodegenLoader(), // 使用生成的资源加载器
  // ...
)
```

### 2. 使用 LocaleKeys（类型安全的翻译键）

```dart
import 'package:easy_localization/easy_localization.dart';
import '../../../../generated/locale_keys.g.dart';

// 方式一：使用 context.tr()
Text(context.tr(LocaleKeys.settings))

// 方式二：使用扩展方法（注意：可能与 GetX 的 tr 冲突）
Text(LocaleKeys.settings.tr())
```

### 3. 示例

```dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../generated/locale_keys.g.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(LocaleKeys.settings)),
      ),
      body: Column(
        children: [
          Text(context.tr(LocaleKeys.home)),
          Text(context.tr(LocaleKeys.language)),
        ],
      ),
    );
  }
}
```

## 优势

1. **性能提升**: CodegenLoader 在编译时加载所有翻译，运行时无需读取文件
2. **类型安全**: LocaleKeys 提供编译时检查，避免拼写错误
3. **IDE 支持**: 自动补全和跳转定义
4. **重构友好**: 重命名翻译键时，IDE 可以自动更新所有引用

## 注意事项

1. **不要手动编辑生成的文件**: 这些文件会在重新生成时被覆盖
2. **使用 context.tr()**: 避免与 GetX 的 tr 方法冲突
3. **及时重新生成**: 修改翻译文件后记得重新生成代码
