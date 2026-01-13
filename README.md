# 合十 App (Heshi App)

基于 Flutter 和 GetX 框架开发的移动应用。

## 📂 项目结构

```
lib/
├── main.dart                 # 应用入口
└── app/
    ├── routes/              # 路由配置
    │   ├── app_pages.dart   # 页面路由定义
    │   └── app_routes.dart  # 路由常量
    ├── widgets/             # 可复用组件
    │   └── tab_container.dart  # Tab 容器组件
    └── modules/             # 功能模块
        ├── privacy/         # 隐私权限检查页面
        ├── login/           # 登录页面
        ├── main/            # 主页面（TabBar 容器）
        ├── home/            # 首页模块
        ├── pet/             # 灵宠模块
        ├── chat/            # 倾诉模块
        ├── mine/            # 我的模块
        ├── yunshi/          # 运势模块（包含日运和月运）
        ├── daily_yunshi/    # 日运子页面
        ├── monthly_yunshi/  # 月运子页面
        ├── my_orders/       # 我的订单
        ├── my_reports/      # 我的报告
        ├── my_profile/      # 我的档案
        ├── settings/        # 设置
        ├── membership/      # 会员
        ├── about/           # 关于我们
        └── feedback/        # 问题反馈
```

## 📱 功能模块说明

### 主要页面
- **首页** - 应用主页面，包含功能入口
- **灵宠** - 宠物相关功能
- **倾诉** - 聊天/倾诉功能
- **我的** - 个人中心，包含用户信息和功能入口

### 功能页面
- **运势** - 查看日运和月运（TabBar 切换）
- **我的订单** - 订单管理
- **我的报告** - 报告查看
- **我的档案** - 个人档案管理
- **设置** - 应用设置
- **会员** - 会员中心
- **关于我们** - 应用信息
- **问题反馈** - 用户反馈

### 系统页面
- **隐私权限** - 隐私协议展示和同意
- **登录** - 用户登录

## 🌍 多语言支持

项目使用 `easy_localization` 实现多语言支持，支持 5 种语言：
- 简体中文 (zh_CN)
- 繁体中文 (zh_TW)
- 英文 (en_US)
- 日语 (ja_JP)
- 韩语 (ko_KR)

### 📝 如何添加新的翻译键

1. **编辑翻译文件**
   
   在 `assets/translations/` 目录下的所有语言文件中添加新的键值对：
   
   ```json
   // assets/translations/zh_CN.json
   {
     "new_key": "新文本"
   }
   
   // assets/translations/en_US.json
   {
     "new_key": "New Text"
   }
   ```
   
   ⚠️ **重要**：必须在所有语言文件中添加相同的键，否则会使用回退语言。

2. **重新生成代码**
   
   **方式一：使用脚本（推荐）**
   
   ```bash
   # macOS/Linux
   ./scripts/generate_i18n.sh
   
   # Windows
   scripts\generate_i18n.bat
   ```
   
   **方式二：手动运行命令**
   
   ```bash
   # 生成资源加载器（CodegenLoader）
   flutter pub run easy_localization:generate -S assets/translations -O lib/generated
   
   # 生成翻译键（LocaleKeys）
   flutter pub run easy_localization:generate -S assets/translations -O lib/generated -f keys -o locale_keys.g.dart
   ```

3. **在代码中使用**
   
   ```dart
   import 'package:easy_localization/easy_localization.dart';
   import '../../../generated/locale_keys.g.dart';
   
   // 方式一：使用 context.tr()（推荐）
   Text(context.tr(LocaleKeys.new_key))
   
   // 方式二：使用 LocaleHelper
   Text(LocaleHelper.tr(context, LocaleKeys.new_key))
   ```

### 🌐 如何添加新语言

1. **创建新的翻译文件**
   
   在 `assets/translations/` 目录下创建新的 JSON 文件，例如 `fr_FR.json`（法语）：
   
   ```json
   {
     "app_name": "合十 App",
     "home": "Accueil",
     "settings": "Paramètres",
     ...
   }
   ```

2. **更新 LocaleService**
   
   在 `lib/app/services/locale_service.dart` 中添加新语言：
   
   ```dart
   static const List<Locale> supportedLocales = [
     Locale('zh', 'CN'),
     Locale('zh', 'TW'),
     Locale('en', 'US'),
     Locale('ja', 'JP'),
     Locale('ko', 'KR'),
     Locale('fr', 'FR'), // 新增法语
   ];
   ```

3. **更新 main.dart**
   
   在 `lib/main.dart` 中添加新语言：
   
   ```dart
   supportedLocales: const [
     Locale('zh', 'CN'),
     Locale('zh', 'TW'),
     Locale('en', 'US'),
     Locale('ja', 'JP'),
     Locale('ko', 'KR'),
     Locale('fr', 'FR'), // 新增法语
   ],
   ```

4. **更新 LocaleService.getLanguageName()**
   
   添加新语言的显示名称：
   
   ```dart
   case 'fr':
     return 'Français';
   ```

5. **更新 iOS 配置（如需要）**
   
   在 `ios/Runner/Info.plist` 中添加语言代码：
   
   ```xml
   <key>CFBundleLocalizations</key>
   <array>
     <string>zh</string>
     <string>en</string>
     <string>ja</string>
     <string>ko</string>
     <string>fr</string> <!-- 新增 -->
   </array>
   ```

6. **重新生成代码**
   
   ```bash
   # 使用脚本（推荐）
   ./scripts/generate_i18n.sh
   
   # 或手动运行
   flutter pub run easy_localization:generate -S assets/translations -O lib/generated
   flutter pub run easy_localization:generate -S assets/translations -O lib/generated -f keys -o locale_keys.g.dart
   ```

### 🔧 如何修改现有翻译

1. **直接编辑翻译文件**
   
   在 `assets/translations/` 目录下找到对应的语言文件，修改值：
   
   ```json
   {
     "settings": "新设置文本"  // 修改这里
   }
   ```

2. **重新生成代码（可选）**
   
   如果只是修改翻译文本，不需要重新生成代码。但如果添加了新键，需要重新生成。

### 📋 翻译文件结构

```
assets/translations/
├── zh_CN.json  # 简体中文
├── zh_TW.json  # 繁体中文
├── en_US.json  # 英文
├── ja_JP.json  # 日语
└── ko_KR.json  # 韩语
```

### ✅ 最佳实践

1. **使用 LocaleKeys** - 类型安全，避免拼写错误
2. **使用 context.tr()** - 避免与 GetX 的 tr 方法冲突
3. **保持翻译文件同步** - 所有语言文件应包含相同的键
4. **及时重新生成** - 添加新键后记得重新生成代码
5. **使用回退翻译** - 配置中已启用 `useFallbackTranslations: true`

### 📚 相关文档

- [多语言使用指南](docs/i18n_usage.md)
- [代码生成使用指南](docs/codegen_usage.md)
- [多语言重构说明](docs/i18n_refactored.md)

## 🛠 常用 Get CLI 命令

```bash
# 创建新页面（包含 controller, view, binding）
get create page:page_name

# 创建控制器
get create controller:controller_name on module_name

# 创建视图
get create view:view_name on module_name

# 创建 Provider
get create provider:provider_name on module_name

# 安装包
get install package_name

# 安装指定版本的包
get install package_name:version

# 安装开发依赖
get install package_name --dev

# 移除包
get remove package_name

# 更新 CLI
get update

# 查看版本
get -v

# 查看帮助
get help
```

更多 Get CLI 使用说明请参考：[docs/get-cli.md](docs/get-cli.md)
