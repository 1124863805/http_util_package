import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/privacy_controller.dart';

class PrivacyView extends GetView<PrivacyController> {
  const PrivacyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.privacy_tip,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 32),
              const Text(
                '隐私政策与用户协议',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '欢迎使用合十 App！\n\n'
                      '我们非常重视您的隐私保护。在使用本应用前，请您仔细阅读并同意以下隐私政策：\n\n'
                      '1. 信息收集\n'
                      '我们仅收集提供服务所必需的信息，包括但不限于设备信息、使用日志等。\n\n'
                      '2. 信息使用\n'
                      '我们使用收集的信息来改进服务质量、提供个性化体验，并确保应用安全运行。\n\n'
                      '3. 信息保护\n'
                      '我们采用行业标准的安全措施保护您的个人信息，防止未经授权的访问、使用或泄露。\n\n'
                      '4. 信息共享\n'
                      '我们不会向第三方出售、交易或转让您的个人信息，除非获得您的明确同意或法律法规要求。\n\n'
                      '5. 用户权利\n'
                      '您有权访问、更正、删除您的个人信息，或撤回同意。\n\n'
                      '6. 政策更新\n'
                      '我们可能会不定期更新本隐私政策，更新后的政策将在应用内公布。\n\n'
                      '继续使用本应用即表示您同意本隐私政策。',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: controller.agreePrivacy,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '同意并继续',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
