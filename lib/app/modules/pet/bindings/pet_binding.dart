import 'package:get/get.dart';

import '../controllers/pet_controller.dart';

class PetBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PetController>(
      () => PetController(),
    );
  }
}
