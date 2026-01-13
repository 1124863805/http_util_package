import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../generated/locale_keys.g.dart';

import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(LocaleKeys.login)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.email, size: 80, color: Colors.blue),
            const SizedBox(height: 32),
            TextField(
              controller: controller.emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: context.tr(LocaleKeys.email),
                hintText: context.tr(LocaleKeys.please_input_email),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.codeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: context.tr(LocaleKeys.verification_code),
                      hintText: context.tr(LocaleKeys.please_input_code),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Obx(
                  () => SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: controller.countdown.value > 0
                          ? null
                          : controller.sendVerificationCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        controller.countdown.value > 0
                            ? '${controller.countdown.value}s'
                            : context.tr(LocaleKeys.send_code),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: controller.login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  context.tr(LocaleKeys.login),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
