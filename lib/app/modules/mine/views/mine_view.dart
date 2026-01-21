import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_localization/easy_localization.dart';

import '../controllers/mine_controller.dart';
import '../../../../generated/locale_keys.g.dart';

class MineView extends GetView<MineController> {
  const MineView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(LocaleKeys.mine)),
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 用户信息区域
            _buildUserSection(context),
            const SizedBox(height: 24),
            // 功能入口列表
            _buildMenuSection(context),
          ],
        ),
      ),
    );
  }

  /// 用户信息区域
  Widget _buildUserSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: controller.goToLogin,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(Icons.person, size: 32, color: Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(LocaleKeys.not_logged_in),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr(LocaleKeys.click_to_login),
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  /// 功能菜单区域
  Widget _buildMenuSection(BuildContext context) {
    final menuItems = [
      _MenuItem(
        icon: Icons.shopping_bag,
        titleKey: "demo测算页面",
        onTap: controller.goToDemo,
        color: Colors.orange,
      ),
      _MenuItem(
        icon: Icons.shopping_bag,
        titleKey: LocaleKeys.my_orders,
        onTap: controller.goToMyOrders,
        color: Colors.orange,
      ),
      _MenuItem(
        icon: Icons.folder,
        titleKey: LocaleKeys.my_profile,
        onTap: controller.goToMyProfile,
        color: Colors.green,
      ),
      _MenuItem(
        icon: Icons.description,
        titleKey: LocaleKeys.my_reports,
        onTap: controller.goToMyReports,
        color: Colors.blue,
      ),
      _MenuItem(
        icon: Icons.settings,
        titleKey: LocaleKeys.settings,
        onTap: controller.goToSettings,
        color: Colors.grey,
      ),
      _MenuItem(
        icon: Icons.star,
        titleKey: LocaleKeys.membership,
        onTap: controller.goToMembership,
        color: Colors.purple,
      ),
      _MenuItem(
        icon: Icons.info,
        titleKey: LocaleKeys.about,
        onTap: controller.goToAbout,
        color: Colors.teal,
      ),
      _MenuItem(
        icon: Icons.feedback,
        titleKey: LocaleKeys.feedback,
        onTap: controller.goToFeedback,
        color: Colors.red,
      ),
    ];

    return Column(
      children: menuItems.map((item) => _buildMenuItem(context, item)).toList(),
    );
  }

  /// 构建菜单项
  Widget _buildMenuItem(BuildContext context, _MenuItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, size: 24, color: item.color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  context.tr(item.titleKey),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

/// 菜单项数据模型
class _MenuItem {
  final IconData icon;
  final String titleKey; // 使用翻译键而不是直接文本
  final VoidCallback onTap;
  final Color color;

  _MenuItem({
    required this.icon,
    required this.titleKey,
    required this.onTap,
    required this.color,
  });
}
