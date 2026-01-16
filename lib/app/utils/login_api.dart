import 'package:dio_http_util/http_util.dart';
import 'auth_util.dart';

/// 登录 API 工具类
/// 封装登录相关的接口调用
class LoginAPI {
  LoginAPI._();

  /// 发送邮箱验证码
  ///
  /// [email] 邮箱地址
  /// [isLoading] 是否显示加载提示（默认 true）
  ///
  /// 返回是否发送成功
  static Future<bool> sendVerificationCode({
    required String email,
    bool isLoading = true,
  }) async {
    final response = await http.send(
      method: hm.post,
      path: '/auth/verify/email',
      data: {"email": email},
      isLoading: isLoading,
    );

    return response.isSuccess;
  }

  /// 邮箱登录
  ///
  /// [email] 邮箱地址
  /// [code] 验证码
  /// [isLoading] 是否显示加载提示（默认 true）
  /// [onFailure] 错误处理回调（可选），如果提供，将优先于全局 onFailure 调用
  ///
  /// 返回 TokenInfo，失败时返回 null
  static Future<TokenInfo?> loginByEmail({
    required String email,
    required String code,
    bool isLoading = true,
    void Function(int? httpStatusCode, int? errorCode, String message)?
    onFailure,
  }) async {
    final tokenInfo = await http
        .send(
          method: hm.post,
          path: '/auth/login/email',
          data: {"email": email, "code": code},
          isLoading: isLoading,
          onFailure: onFailure,
        )
        .extractModel<TokenInfo>(TokenInfo.fromJson);

    return tokenInfo;
  }
}
