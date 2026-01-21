import 'package:get/get.dart';

import '../controllers/main_controller.dart';
import '../../home/bindings/home_binding.dart';
import '../../pet/bindings/pet_binding.dart';
import '../../chat/bindings/chat_binding.dart';
import '../../mine/bindings/mine_binding.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    // 注册 MainController
    Get.lazyPut<MainController>(() => MainController());

    // 统一初始化所有子页面的 Controller
    HomeBinding().dependencies();
    PetBinding().dependencies();
    ChatBinding().dependencies();
    MineBinding().dependencies();
  }
}
