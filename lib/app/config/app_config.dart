/// 应用配置
/// 编译时环境变量配置（单例）
class AppConfig {
  AppConfig._();

  static AppConfig? _instance;

  /// 单例获取
  static AppConfig get instance {
    _instance ??= AppConfig._();
    return _instance!;
  }

  // 编译时获取环境变量（必须在编译时确定）
  /// 应用标识
  static const String app = String.fromEnvironment(
    'APP',
    defaultValue: 'heyun',
  );

  /// 构建风味
  static const String flavor = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'heyun_ios',
  );
}
