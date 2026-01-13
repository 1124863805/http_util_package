import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../../../utils/privacy_util.dart';
import '../../../utils/user_agent_util.dart';

class PrivacyController extends GetxController {
  /// 用户同意隐私协议
  Future<void> agreePrivacy() async {
    await PrivacyUtil.setPrivacyAgreed(true);
    // 清除 User-Agent 缓存，以便重新构建
    UserAgentUtil.clearCache();
    Get.offAllNamed(Routes.MAIN);
  }
}
