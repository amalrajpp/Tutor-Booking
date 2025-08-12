import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:karreoapp/presentation/controllers/auth_controller.dart';
import 'package:karreoapp/presentation/pages/splash_page.dart';
import 'package:karreoapp/presentation/pages/student/student_details_page.dart';
import 'package:karreoapp/presentation/pages/student/student_home.dart';
import 'package:karreoapp/presentation/pages/student/student_home_binding.dart';
import 'package:karreoapp/presentation/pages/tutor/tutor_details_page.dart';
import 'package:karreoapp/presentation/pages/tutor/tutor_home.dart';
import 'package:karreoapp/presentation/pages/tutor/tutor_home_binding.dart';
import '../data/repositories_impl/auth_repository_impl.dart';
import '../presentation/pages/login_page.dart';
import '../presentation/pages/signup_page.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: '/login',
      page: () => LoginPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => AuthController(AuthRepositoryImpl()));
      }),
    ),
    GetPage(name: '/signup', page: () => SignUpPage()),
    GetPage(name: '/studentDetails', page: () => StudentDetailsPage()),
    GetPage(name: '/tutorDetails', page: () => TutorDetailsPage()),
    GetPage(
      name: '/studentHome',
      page: () => StudentHomePage(),
      binding: StudentHomeBinding(),
    ),
    GetPage(
      name: '/tutorHome',
      page: () => TutorHomePage(),
      binding: TutorHomeBinding(),
    ),
    // in lib/routes/app_pages.dart
    GetPage(name: '/splash', page: () => const SplashPage()),
  ];
}
