import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../routes/app_pages.dart';

class PrivacyController extends GetxController {
  final _storage = GetStorage();
  final _privacyAgreedKey = 'privacy_agreed';

  /// 用户同意隐私协议
  void agreePrivacy() {
    _storage.write(_privacyAgreedKey, true);
    Get.offAllNamed(Routes.MAIN);
  }
}
