import 'package:shared_preferences/shared_preferences.dart';

const _kAgreedKey = 'privacy_agreement_agreed';

/// 隐私协议「已同意」持久化（供弹窗与 [PrivacyAgreementHelper] 共用）
class PrivacyPrefs {
  PrivacyPrefs._();

  static SharedPreferences? _prefs;

  static Future<void> _ensure() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<bool> hasAgreed() async {
    await _ensure();
    return _prefs!.getBool(_kAgreedKey) ?? false;
  }

  static Future<void> markAgreed() async {
    await _ensure();
    await _prefs!.setBool(_kAgreedKey, true);
  }

  static Future<void> clearAgreed() async {
    await _ensure();
    await _prefs!.remove(_kAgreedKey);
  }
}
