import 'package:get_storage/get_storage.dart';

class TokenInfo {
  String? uid;
  String? accessToken;
  String? refreshToken;
  int? expiresIn;

  TokenInfo({this.uid, this.accessToken, this.refreshToken, this.expiresIn});

  TokenInfo.fromJson(Map<String, dynamic> json) {
    uid = json['uid'];
    accessToken = json['accessToken'];
    refreshToken = json['refreshToken'];
    expiresIn = json['expiresIn'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['uid'] = this.uid;
    data['accessToken'] = this.accessToken;
    data['refreshToken'] = this.refreshToken;
    data['expiresIn'] = this.expiresIn;
    return data;
  }
}

/// 认证工具类
/// 统一管理用户登录信息和 Token
class AuthUtil {
  AuthUtil._();

  static final _storage = GetStorage();
  static const String _accessTokenKey = 'access_token';
  static const String _emailKey = 'email';

  /// 保存登录信息
  static Future<void> saveLoginInfo({
    required String accessToken,
    String? email,
  }) async {
    await _storage.write(_accessTokenKey, accessToken);
    if (email != null) {
      await _storage.write(_emailKey, email);
    }
  }

  /// 获取 Access Token
  static String? getAccessToken() {
    return _storage.read<String>(_accessTokenKey);
  }

  /// 获取邮箱
  static String? getEmail() {
    return _storage.read<String>(_emailKey);
  }

  /// 检查是否已登录
  static bool isLoggedIn() {
    final token = getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// 清除登录信息
  static Future<void> clearLoginInfo() async {
    await _storage.remove(_accessTokenKey);
    await _storage.remove(_emailKey);
  }
}
