import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/about_controller.dart';

class AboutView extends GetView<AboutController> {
  const AboutView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于我们'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          '关于我们',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
