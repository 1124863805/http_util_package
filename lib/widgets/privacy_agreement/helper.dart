import 'package:flutter/material.dart';

import 'dialog.dart';
import 'privacy_prefs.dart';

/// 隐私协议辅助类
///
/// 负责：1）持久化用户是否已同意；2）在需要时弹出协议并返回结果。
class PrivacyAgreementHelper {
  PrivacyAgreementHelper._();

  /// 是否已同意过协议
  static Future<bool> hasAgreed() => PrivacyPrefs.hasAgreed();

  /// 标记为已同意（用于 PrivacyGate 等场景，弹窗同意后持久化）
  static Future<void> markAgreed() => PrivacyPrefs.markAgreed();

  /// 清除同意状态（用于测试或重新展示）
  static Future<void> clearAgreed() => PrivacyPrefs.clearAgreed();

  /// 弹出协议弹窗，返回用户选择（true 同意 / false 拒绝 / null 关闭）
  static Future<bool?> show(
    BuildContext context, {
    PrivacyAgreementConfig config = const PrivacyAgreementConfig(),
  }) async {
    if (!context.mounted) return null;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PrivacyAgreementDialog(config: config),
    );
  }

  /// 若未同意过则弹出协议，否则直接返回 true。
  /// [context] 需为已挂载的 BuildContext。
  /// 返回 true 表示用户已同意（含之前已同意），false 表示本次拒绝。
  static Future<bool> showIfNeeded(
    BuildContext context, {
    PrivacyAgreementConfig config = const PrivacyAgreementConfig(),
  }) async {
    if (await hasAgreed()) return true;
    final agreed = await show(context, config: config);
    return agreed ?? false;
  }
}
