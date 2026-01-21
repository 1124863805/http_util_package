@echo off
REM 多语言代码生成脚本 (Windows)
REM 使用方法: scripts\generate_i18n.bat

echo 🌍 开始生成多语言代码...

REM 生成资源加载器（CodegenLoader）
echo 📦 生成资源加载器...
flutter pub run easy_localization:generate -S assets/translations -O lib/generated

if %errorlevel% neq 0 (
    echo ❌ 资源加载器生成失败
    exit /b 1
)

echo ✅ 资源加载器生成成功

REM 生成翻译键（LocaleKeys）
echo 🔑 生成翻译键...
flutter pub run easy_localization:generate -S assets/translations -O lib/generated -f keys -o locale_keys.g.dart

if %errorlevel% neq 0 (
    echo ❌ 翻译键生成失败
    exit /b 1
)

echo ✅ 翻译键生成成功
echo.
echo 🎉 所有代码生成完成！
