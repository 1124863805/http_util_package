import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../generated/locale_keys.g.dart';

import '../controllers/main_controller.dart';
import '../../home/views/home_view.dart';
import '../../pet/views/pet_view.dart';
import '../../chat/views/chat_view.dart';
import '../../mine/views/mine_view.dart';

class MainView extends GetView<MainController> {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const HomeView(),
      const PetView(),
      ChatView(), // 不能使用 const，因为 ChatView 包含 TextEditingController
      const MineView(),
    ];

    return Scaffold(
      body: Obx(
        () =>
            IndexedStack(index: controller.currentIndex.value, children: pages),
      ),
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          currentIndex: controller.currentIndex.value,
          onTap: controller.changeTab,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home),
              label: context.tr(LocaleKeys.home),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.pets),
              label: context.tr(LocaleKeys.pet),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.chat_bubble_outline),
              label: context.tr(LocaleKeys.chat),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person),
              label: context.tr(LocaleKeys.mine),
            ),
          ],
        ),
      ),
    );
  }
}
