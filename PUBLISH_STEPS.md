# 发布步骤总结

## ✅ 已完成

1. ✅ 创建独立的 package 目录：`/Users/tomas/StudioProjects/http_util_package`
2. ✅ 复制所有源代码文件到 `lib/` 目录
3. ✅ 创建 `pubspec.yaml`
4. ✅ 创建 `CHANGELOG.md`
5. ✅ 创建 `LICENSE` (MIT)
6. ✅ 创建 `README.md`
7. ✅ 创建 `.gitignore`
8. ✅ 创建 `analysis_options.yaml`
9. ✅ 运行 `flutter pub get` - 成功
10. ✅ 运行 `flutter analyze` - 通过（只有 1 个 info 级别的提示）
11. ✅ 运行 `flutter pub publish --dry-run` - **通过！**

## ⚠️ 发布前需要修改

### 1. 修改 `pubspec.yaml` 中的以下信息：

```yaml
# 需要修改的行：
homepage: https://github.com/yourusername/http_util      # 改为你的 GitHub 地址
repository: https://github.com/yourusername/http_util     # 改为你的 GitHub 地址
issue_tracker: https://github.com/yourusername/http_util/issues  # 改为你的 GitHub 地址
```

**如果没有 GitHub 仓库，可以：**
- 创建 GitHub 仓库
- 或者删除这三行（不推荐）

### 2. 检查包名是否可用

当前包名是 `http_util`，可能已被占用。如果被占用，需要：
1. 访问 https://pub.dev/packages/http_util 检查
2. 如果被占用，修改 `pubspec.yaml` 中的 `name` 字段，例如：
   - `dio_http_util`
   - `http_util_x`
   - `http_util_helper`
   - 或其他唯一名称

## 📋 发布命令

### 步骤 1: 登录 pub.dev

```bash
cd /Users/tomas/StudioProjects/http_util_package
flutter pub login
```

这会打开浏览器，需要：
1. 使用 Google 账号登录
2. 授权 pub.dev 访问
3. 复制授权码粘贴到终端

### 步骤 2: 正式发布

```bash
flutter pub publish
```

**注意：** 发布后无法撤销，但可以发布新版本修复问题。

## 📝 检查清单

发布前确认：
- [ ] 修改了 `pubspec.yaml` 中的 GitHub 地址（如果有）
- [ ] 确认包名 `http_util` 在 pub.dev 上可用
- [ ] 确认版本号 `1.0.0` 正确
- [ ] 确认所有文件都在正确位置
- [ ] 已登录 pub.dev 账号

## 🎉 发布后

发布成功后：
1. 访问 `https://pub.dev/packages/http_util` 查看你的 package
2. 等待几分钟让 pub.dev 处理
3. 可以在其他项目中使用：

```yaml
dependencies:
  http_util: ^1.0.0
```

## 📦 目录结构

```
/Users/tomas/StudioProjects/http_util_package/
├── lib/
│   ├── api_response.dart
│   ├── http_config.dart
│   ├── http_method.dart
│   ├── http_util.dart
│   └── http_util_impl.dart
├── CHANGELOG.md
├── LICENSE
├── README.md
├── .gitignore
├── analysis_options.yaml
├── pubspec.yaml
└── PUBLISH_STEPS.md (本文件)
```

## ⚠️ 注意事项

1. **包名唯一性**：确保包名未被占用
2. **版本号**：遵循语义化版本规范
3. **无法撤销**：发布后无法删除版本，只能发布新版本
4. **GitHub 仓库**：虽然不是必须的，但强烈推荐

## 🚀 快速发布

如果一切准备就绪，直接运行：

```bash
cd /Users/tomas/StudioProjects/http_util_package
flutter pub login    # 首次需要
flutter pub publish  # 正式发布
```
