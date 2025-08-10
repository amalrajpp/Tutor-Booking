import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:karreoapp/data/repositories_impl/auth_repository_impl.dart';
import 'package:karreoapp/firebase_options.dart';
import 'package:karreoapp/presentation/controllers/auth_controller.dart';
import 'package:karreoapp/routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  Get.put<AuthController>(AuthController(AuthRepositoryImpl()));
  runApp(
    GetMaterialApp(
      initialRoute: '/splash', // <--- Use splash instead of /login
      getPages: AppPages.routes,
    ),
  );
}
