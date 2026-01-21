import 'package:get/get.dart';

import '../controllers/birth_info_form_controller.dart';

class BirthInfoFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BirthInfoFormController>(
      () => BirthInfoFormController(),
    );
  }
}
