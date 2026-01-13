import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/pet_controller.dart';

class PetView extends GetView<PetController> {
  const PetView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('灵宠'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          '灵宠',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
