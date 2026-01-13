import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/membership_controller.dart';

class MembershipView extends GetView<MembershipController> {
  const MembershipView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('会员'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          '会员',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
