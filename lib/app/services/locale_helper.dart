import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

/// 多语言辅助类
/// 提供便捷的翻译方法，基于 easy_localization 的最佳实践
class LocaleHelper {
  LocaleHelper._();

  /// 翻译文本（推荐使用 context.tr()）
  /// 使用示例: LocaleHelper.tr(context, 'home')
  static String tr(BuildContext context, String key,
      {List<String>? args, Map<String, String>? namedArgs, String? gender}) {
    return context.tr(key, args: args, namedArgs: namedArgs, gender: gender);
  }

  /// 翻译文本（静态方法，不推荐在 build 中使用）
  /// 使用示例: LocaleHelper.trStatic('home')
  static String trStatic(String key,
      {List<String>? args, Map<String, String>? namedArgs, String? gender}) {
    return key.tr(args: args, namedArgs: namedArgs, gender: gender);
  }

  /// 翻译文本（带参数）
  /// 使用示例: LocaleHelper.trWithArgs(context, 'welcome', namedArgs: {'name': 'John'})
  static String trWithArgs(BuildContext context, String key,
      Map<String, String> namedArgs) {
    return context.tr(key, namedArgs: namedArgs);
  }

  /// 翻译文本（复数形式）
  /// 使用示例: LocaleHelper.plural(context, 'item', count)
  static String plural(BuildContext context, String key, num value,
      {List<String>? args,
      Map<String, String>? namedArgs,
      String? name,
      NumberFormat? format}) {
    return context.plural(key, value,
        args: args, namedArgs: namedArgs, name: name, format: format);
  }

  /// 翻译文本（复数形式，静态方法）
  /// 使用示例: LocaleHelper.pluralStatic('item', count)
  static String pluralStatic(String key, num value,
      {List<String>? args,
      Map<String, String>? namedArgs,
      String? name,
      NumberFormat? format}) {
    return key.plural(value,
        args: args, namedArgs: namedArgs, name: name, format: format);
  }
}
