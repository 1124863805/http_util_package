# 多语言操作规范（AI 模型使用）

## 📋 核心规则

### 1. 翻译文件管理
- **所有翻译文件必须同步更新**：修改任何语言的翻译时，必须在所有语言文件中添加/修改相同的键
- **文件位置**：`assets/translations/` 目录下
- **文件命名**：`{languageCode}-{countryCode}.json`（如 `zh_CN.json`, `en_US.json`）
- **当前支持的语言**：zh_CN, zh_TW, en_US, ja_JP, ko_KR

### 2. 添加新翻译键的流程
1. 在所有语言文件中添加相同的键（必须）
2. 运行生成脚本：`./scripts/generate_i18n.sh`
3. 在代码中使用：`context.tr(LocaleKeys.xxx)`

### 3. 代码中使用翻译
- **必须使用**：`context.tr(LocaleKeys.xxx)`（避免与 GetX 的 tr 冲突）
- **禁止使用**：直接写死的中文字符串
- **类型安全**：使用 `LocaleKeys` 常量，不要使用字符串

### 4. 添加新语言的流程
1. 创建翻译文件：`assets/translations/{lang}_{country}.json`
2. 更新 `LocaleService.supportedLocales`
3. 更新 `main.dart` 中的 `supportedLocales`
4. 更新 `LocaleService.getLanguageName()` 方法
5. 更新 iOS `Info.plist` 的 `CFBundleLocalizations`
6. 运行生成脚本

### 5. 修改现有翻译
- 直接编辑翻译文件即可（无需重新生成，除非添加了新键）
- 修改后需要重新生成代码

## 🚫 禁止事项

1. ❌ 不要在代码中写死中文字符串
2. ❌ 不要只在一个语言文件中添加键，必须在所有语言文件中添加
3. ❌ 不要使用字符串作为翻译键，必须使用 `LocaleKeys`
4. ❌ 不要使用 `'key'.tr()`，必须使用 `context.tr(LocaleKeys.key)`

## ✅ 必须事项

1. ✅ 所有翻译键必须在所有语言文件中存在
2. ✅ 使用 `context.tr(LocaleKeys.xxx)` 进行翻译
3. ✅ 添加新键后必须运行生成脚本
4. ✅ 保持翻译文件结构一致

## 📝 快速检查清单

修改多语言相关代码时，检查：
- [ ] 所有语言文件都已更新
- [ ] 已运行生成脚本
- [ ] 代码中使用 `context.tr(LocaleKeys.xxx)`
- [ ] 没有写死的中文字符串

## 🔧 常用命令

```bash
# 生成多语言代码
./scripts/generate_i18n.sh

# 或手动生成
flutter pub run easy_localization:generate -S assets/translations -O lib/generated
flutter pub run easy_localization:generate -S assets/translations -O lib/generated -f keys -o locale_keys.g.dart
```
