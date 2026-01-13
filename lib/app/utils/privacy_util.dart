import 'package:get_storage/get_storage.dart';

/// 隐私政策工具类
/// 统一管理隐私政策同意状态
class PrivacyUtil {
  PrivacyUtil._();

  static final _storage = GetStorage();
  static const String _privacyAgreedKey = 'privacy_agreed';

  /// 检查用户是否已同意隐私政策
  static bool isPrivacyAgreed() {
    return _storage.read<bool>(_privacyAgreedKey) ?? false;
  }

  /// 设置隐私政策同意状态
  static Future<void> setPrivacyAgreed(bool agreed) async {
    await _storage.write(_privacyAgreedKey, agreed);
  }

  /// 清除隐私政策同意状态
  static Future<void> clearPrivacyAgreed() async {
    await _storage.remove(_privacyAgreedKey);
  }
}
