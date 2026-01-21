import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'privacy_util.dart';

/// User-Agent 工具类
/// 用于构建 HTTP 请求的 User-Agent 字符串
class UserAgentUtil {
  UserAgentUtil._();

  static String? _cachedUserAgent;

  /// 构建 User-Agent
  /// 如果用户未同意隐私政策，返回空字符串
  static Future<String> buildUserAgent() async {
    // 检查用户是否已同意隐私政策
    if (!PrivacyUtil.isPrivacyAgreed()) {
      return "";
    }

    // 如果已缓存，直接返回
    if (_cachedUserAgent != null) {
      return _cachedUserAgent!;
    }

    // 用户已同意隐私政策，可以获取详细设备信息
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = packageInfo.version;
      final buildNumber = packageInfo.buildNumber;

      final deviceInfoPlugin = DeviceInfoPlugin();

      String userAgent = "";
      if (Platform.isAndroid) {
        final info = await deviceInfoPlugin.androidInfo;
        userAgent =
            'Mozilla/5.0 (Linux; Android ${info.version.release}; ${info.model}) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Mobile Safari/537.36 $appVersion ($buildNumber)';
      } else if (Platform.isIOS) {
        final info = await deviceInfoPlugin.iosInfo;
        userAgent =
            'Mozilla/5.0 (iPhone; CPU iPhone OS ${info.systemVersion.replaceAll('.', '_')} like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1 $appVersion ($buildNumber)';
      }

      // 缓存 User-Agent
      _cachedUserAgent = userAgent;
      return userAgent;
    } catch (e) {
      // 如果获取失败，返回空字符串
      return "";
    }
  }

  /// 清除缓存的 User-Agent（当隐私政策状态改变时调用）
  static void clearCache() {
    _cachedUserAgent = null;
  }
}
