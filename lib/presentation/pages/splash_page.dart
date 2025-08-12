import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Trigger autoLogin when this page is built
    Future.microtask(() async {
      final authController = Get.find<AuthController>();
      await authController.autoLogin();
    });

    return Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
