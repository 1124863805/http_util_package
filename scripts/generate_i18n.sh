#!/bin/bash

# 多语言代码生成脚本
# 使用方法: ./scripts/generate_i18n.sh

echo "🌍 开始生成多语言代码..."

# 生成资源加载器（CodegenLoader）
echo "📦 生成资源加载器..."
flutter pub run easy_localization:generate -S assets/translations -O lib/generated

if [ $? -eq 0 ]; then
    echo "✅ 资源加载器生成成功"
else
    echo "❌ 资源加载器生成失败"
    exit 1
fi

# 生成翻译键（LocaleKeys）
echo "🔑 生成翻译键..."
flutter pub run easy_localization:generate -S assets/translations -O lib/generated -f keys -o locale_keys.g.dart

if [ $? -eq 0 ]; then
    echo "✅ 翻译键生成成功"
    echo ""
    echo "🎉 所有代码生成完成！"
else
    echo "❌ 翻译键生成失败"
    exit 1
fi
